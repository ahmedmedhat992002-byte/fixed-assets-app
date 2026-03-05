import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { buildAssetEvent } from "./assetEventFactory";
import { canPerform } from "./roles";
import {
    FailedOperation,
    SyncOperation,
    SyncResult,
    UserRole,
} from "./types";

const db = admin.firestore();

/**
 * syncBatch — the single entry point for all client writes.
 *
 * Called by Flutter's SyncService with a list of SyncOperation objects.
 * For each operation it:
 *   1. Validates authentication and role permissions.
 *   2. Runs a Firestore transaction (atomic read → version check → write).
 *   3. Generates an asset_event document inside the same transaction.
 *   4. Returns { applied[], failed[], conflicts[] }.
 *
 * The client MUST NOT write to Firestore directly (rules enforce this).
 */
export const syncBatch = functions.https.onCall(
    async (
        data: { operations: SyncOperation[] },
        context: functions.https.CallableContext
    ): Promise<SyncResult> => {
        // ── 1. Authentication guard ───────────────────────────────────────────
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "You must be signed in to sync data."
            );
        }

        const uid = context.auth.uid;

        // ── 2. Fetch caller's profile (companyId + role) ──────────────────────
        const userSnap = await db.collection("users").doc(uid).get();
        if (!userSnap.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "User profile not found. Contact your administrator."
            );
        }

        const userData = userSnap.data()!;
        const companyId = userData["companyId"] as string;
        const role = (userData["role"] as UserRole) ?? "viewer";

        if (!companyId) {
            throw new functions.https.HttpsError(
                "failed-precondition",
                "User is not associated with a company."
            );
        }

        // ── 3. Validate input ─────────────────────────────────────────────────
        const ops: SyncOperation[] = data.operations ?? [];
        if (!Array.isArray(ops) || ops.length === 0) {
            return { applied: [], failed: [], conflicts: [] };
        }

        const result: SyncResult = { applied: [], failed: [], conflicts: [] };

        // ── 4. Process each operation ─────────────────────────────────────────
        for (const op of ops) {
            // Basic payload validation.
            if (!op.operationId || !op.type || !op.collection || !op.documentId) {
                const err: FailedOperation = {
                    operationId: op.operationId ?? "unknown",
                    reason: "invalid_payload: missing required fields",
                };
                result.failed.push(err);
                continue;
            }

            // Role permission check.
            if (!canPerform(role, op.collection, op.type)) {
                result.failed.push({
                    operationId: op.operationId,
                    reason: `forbidden: role '${role}' cannot '${op.type}' on '${op.collection}'`,
                });
                continue;
            }

            try {
                await db.runTransaction(async (tx) => {
                    // ── Document references ─────────────────────────────────────────
                    const docRef = db
                        .collection("companies")
                        .doc(companyId)
                        .collection(op.collection)
                        .doc(op.documentId);

                    const docSnap = await tx.get(docRef);
                    const serverData = docSnap.exists
                        ? (docSnap.data() as Record<string, unknown>)
                        : null;
                    const serverVersion: number =
                        serverData ? ((serverData["version"] as number) ?? 0) : 0;

                    // ── Conflict detection ──────────────────────────────────────────
                    if (op.type !== "create" && serverVersion > op.baseVersion) {
                        result.conflicts.push({
                            operationId: op.operationId,
                            reason: "version_conflict",
                            conflictDetail: {
                                serverVersion,
                                serverData: serverData ?? {},
                            },
                        });
                        return; // abort this operation's transaction
                    }

                    // ── Apply operation ─────────────────────────────────────────────
                    const newVersion = serverVersion + 1;
                    const now = admin.firestore.FieldValue.serverTimestamp();

                    if (op.type === "delete") {
                        tx.delete(docRef);
                    } else {
                        // Build the document to write — strip client-only fields.
                        const writePayload: Record<string, unknown> = {
                            ...op.payload,
                            companyId,
                            version: newVersion,
                            lastModifiedAt: now,
                            lastModifiedBy: uid,
                            lastModifiedDevice: op.deviceId,
                        };
                        // Remove internal hint so it doesn't pollute Firestore docs.
                        delete writePayload["eventType"];

                        if (op.type === "create") {
                            tx.set(docRef, writePayload);
                        } else {
                            // update: merge to avoid overwriting unrelated fields.
                            tx.set(docRef, writePayload, { merge: true });
                        }
                    }

                    // ── Generate asset_event (assets collection only) ───────────────
                    if (op.collection === "assets" && op.type !== "delete") {
                        const eventRef = db
                            .collection("companies")
                            .doc(companyId)
                            .collection("asset_events")
                            .doc();

                        const newData: Record<string, unknown> = {
                            ...op.payload,
                            companyId,
                            version: newVersion,
                        };
                        delete newData["eventType"];

                        const event = buildAssetEvent(
                            op,
                            serverData,
                            newData,
                            uid,
                            companyId
                        );
                        tx.set(eventRef, event);
                    }

                    result.applied.push(op.operationId);
                });
            } catch (err) {
                functions.logger.error(`syncBatch op ${op.operationId} failed`, err);
                result.failed.push({
                    operationId: op.operationId,
                    reason: err instanceof Error ? err.message : String(err),
                });
            }
        }

        return result;
    }
);

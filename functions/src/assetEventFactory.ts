import { AssetEvent, AssetEventType, SyncOperation } from "./types";
import { FieldValue } from "firebase-admin/firestore";

/**
 * Derives the correct AssetEventType from a SyncOperation.
 *
 * Priority order:
 *   1. Explicit 'eventType' field in payload (set by AssetRepository)
 *   2. status change → 'disposed', 'maintenance'
 *   3. assignedTo changed → 'assign'
 *   4. location changed → 'transfer'
 *   5. op.type === 'create' → 'create'
 *   6. op.type === 'delete' → 'dispose'
 *   7. default → 'update'
 */
function deriveEventType(
    op: SyncOperation,
    previous: Record<string, unknown> | null
): AssetEventType {
    const payload = op.payload;

    // Explicit hint from client.
    if (payload["eventType"]) {
        const hint = payload["eventType"] as string;
        const validTypes: AssetEventType[] = [
            "create", "update", "transfer", "assign",
            "check", "maintenance", "dispose",
        ];
        if (validTypes.includes(hint as AssetEventType)) {
            return hint as AssetEventType;
        }
    }

    if (op.type === "create") return "create";
    if (op.type === "delete") return "dispose";

    // Status-driven events.
    if (payload["status"] === "disposed") return "dispose";
    if (payload["status"] === "maintenance") return "maintenance";

    // Field-change-driven events (compare to previous state).
    if (previous) {
        if (
            payload["assignedTo"] !== undefined &&
            payload["assignedTo"] !== previous["assignedTo"]
        ) return "assign";

        if (
            payload["location"] !== undefined &&
            payload["location"] !== previous["location"]
        ) return "transfer";
    }

    return "update";
}

/**
 * Builds an AssetEvent document ready to be written to Firestore.
 */
export function buildAssetEvent(
    op: SyncOperation,
    previousData: Record<string, unknown> | null,
    newData: Record<string, unknown>,
    uid: string,
    companyId: string
): AssetEvent {
    const eventType = deriveEventType(op, previousData);
    const notes = op.payload["notes"] as string | undefined;

    // Strip the internal eventType hint before storing state snapshots.
    const cleanPrev = previousData
        ? { ...previousData }
        : null;

    const cleanNew = { ...newData };
    delete cleanNew["eventType"];

    return {
        assetId: op.documentId,
        type: eventType,
        companyId,
        performedBy: uid,
        performedAt: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.FieldValue,
        deviceId: op.deviceId,
        previousState: cleanPrev,
        newState: cleanNew,
        ...(notes ? { notes } : {}),
    };
}

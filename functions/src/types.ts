// ── Sync Contract Types ───────────────────────────────────────────────────────
// These types must stay in sync with lib/core/sync/ on the Flutter side.

export type OpType = "create" | "update" | "delete";

export type AssetEventType =
    | "create"
    | "update"
    | "transfer"
    | "assign"
    | "check"
    | "maintenance"
    | "dispose";

export type UserRole = "admin" | "manager" | "viewer";

// ── Operation (sent by mobile client via syncBatch) ───────────────────────────

export interface SyncOperation {
    /** UUID v4 — used for idempotency */
    operationId: string;
    /** 'create' | 'update' | 'delete' */
    type: OpType;
    /** Firestore sub-collection, e.g. 'assets' */
    collection: string;
    /** Target document ID */
    documentId: string;
    /** Full or partial document payload */
    payload: Record<string, unknown>;
    /**
     * The version the client believes the document is on.
     * Set to 0 for create. If server version > baseVersion → conflict.
     */
    baseVersion: number;
    /** Stable device identifier — populates lastModifiedDevice on documents */
    deviceId: string;
    /** Client Unix epoch ms — used for last-write-wins conflict resolution */
    timestamp: number;
}

// ── Responses ─────────────────────────────────────────────────────────────────

export interface FailedOperation {
    operationId: string;
    reason: string;
    conflictDetail?: {
        serverVersion: number;
        serverData: Record<string, unknown>;
    };
}

export interface SyncResult {
    /** operationIds that were applied and persisted */
    applied: string[];
    /** Ops that failed for reasons other than conflicts (e.g. auth, validation) */
    failed: FailedOperation[];
    /** Ops that collided against a newer server version */
    conflicts: FailedOperation[];
}

// ── Asset Event ───────────────────────────────────────────────────────────────

export interface AssetEvent {
    assetId: string;
    type: AssetEventType;
    companyId: string;
    performedBy: string; // uid
    performedAt: FirebaseFirestore.FieldValue;
    deviceId: string;
    previousState: Record<string, unknown> | null;
    newState: Record<string, unknown>;
    notes?: string;
}

// Import only for type reference (not runtime import).
import { FieldValue } from "firebase-admin/firestore";
export type { FieldValue };

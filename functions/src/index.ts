import * as admin from "firebase-admin";

// Initialize Admin SDK once (idempotent in emulator and prod).
admin.initializeApp();

// Export all Cloud Functions.
export { syncBatch } from "./syncBatch";

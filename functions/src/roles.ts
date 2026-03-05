import { UserRole } from "./types";

/** Operations allowed for each role. */
const ROLE_PERMISSIONS: Record<UserRole, Record<string, string[]>> = {
    admin: {
        assets: ["create", "update", "delete"],
        users: ["create", "update", "delete"],
    },
    manager: {
        assets: ["create", "update"],
        users: [],
    },
    viewer: {
        assets: [],
        users: [],
    },
};

/**
 * Returns true if [role] can perform [opType] on [collection].
 */
export function canPerform(
    role: UserRole,
    collection: string,
    opType: string
): boolean {
    const perms = ROLE_PERMISSIONS[role];
    if (!perms) return false;
    const allowed = perms[collection] ?? [];
    return allowed.includes(opType);
}

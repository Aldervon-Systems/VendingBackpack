import { ACCESS_POLICIES, ADMIN_PROFILES, APPROVAL_REQUESTS } from "@/admin-center-data";
import type { AccessRepository } from "@/features/access/lib/access-repository";

export class LocalAccessRepository implements AccessRepository {
  getAccessSnapshot() {
    return {
      adminProfiles: ADMIN_PROFILES,
      approvalRequests: APPROVAL_REQUESTS,
      accessPolicies: ACCESS_POLICIES,
    };
  }
}

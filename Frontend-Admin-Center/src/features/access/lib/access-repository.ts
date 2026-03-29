import { ACCESS_POLICIES, type ApprovalRequest, type AdminProfile } from "@/admin-center-data";

export type AccessPolicy = (typeof ACCESS_POLICIES)[number];

export type AccessSnapshot = {
  adminProfiles: AdminProfile[];
  approvalRequests: ApprovalRequest[];
  accessPolicies: AccessPolicy[];
};

export interface AccessRepository {
  getAccessSnapshot(): AccessSnapshot;
}

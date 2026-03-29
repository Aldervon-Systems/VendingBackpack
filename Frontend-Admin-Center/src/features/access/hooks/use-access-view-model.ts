"use client";

import { useMemo } from "react";
import { LocalAccessRepository } from "@/features/access/lib/local-access-repository";

const accessRepository = new LocalAccessRepository();

export function useAccessViewModel() {
  const snapshot = useMemo(() => accessRepository.getAccessSnapshot(), []);

  return {
    ...snapshot,
    approvedAdminCount: snapshot.adminProfiles.length,
    pendingRequestCount: snapshot.approvalRequests.length,
    policySetCount: snapshot.accessPolicies.length,
  };
}

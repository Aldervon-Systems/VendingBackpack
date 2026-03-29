import { ONBOARDING_QUEUE, ORGANIZATIONS } from "@/admin-center-data";
import type { OrganizationsRepository } from "@/features/organizations/lib/organizations-repository";

export class LocalOrganizationsRepository implements OrganizationsRepository {
  listOrganizations() {
    return {
      organizations: ORGANIZATIONS,
      onboardingQueue: ONBOARDING_QUEUE,
    };
  }
}

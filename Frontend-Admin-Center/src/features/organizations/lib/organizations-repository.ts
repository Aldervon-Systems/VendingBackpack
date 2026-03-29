import { ONBOARDING_QUEUE, type OrganizationRecord } from "@/admin-center-data";

export type OnboardingQueueItem = (typeof ONBOARDING_QUEUE)[number];

export type OrganizationsSnapshot = {
  organizations: OrganizationRecord[];
  onboardingQueue: OnboardingQueueItem[];
};

export interface OrganizationsRepository {
  listOrganizations(): OrganizationsSnapshot;
}

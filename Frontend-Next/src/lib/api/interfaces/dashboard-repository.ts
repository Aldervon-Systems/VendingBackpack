import type { DashboardSnapshot } from "@/types/dashboard";
import type { UserRole } from "@/types/auth";

export interface DashboardRepository {
  getSnapshot(role: UserRole): Promise<DashboardSnapshot>;
}
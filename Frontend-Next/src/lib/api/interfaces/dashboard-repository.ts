import type { DashboardSnapshot, DashboardViewPreferences } from "@/types/dashboard";
import type { UserRole } from "@/types/auth";

export interface DashboardRepository {
  getSnapshot(role: UserRole): Promise<DashboardSnapshot>;
  getPreferences(): Promise<DashboardViewPreferences>;
  savePreferences(preferences: DashboardViewPreferences): Promise<DashboardViewPreferences>;
}

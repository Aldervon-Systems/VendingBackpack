import type { CorporateSnapshot, CorporateViewPreferences } from "@/types/corporate";

export interface CorporateRepository {
  getSnapshot(): Promise<CorporateSnapshot>;
  getPreferences(): Promise<CorporateViewPreferences>;
  savePreferences(preferences: CorporateViewPreferences): Promise<CorporateViewPreferences>;
}

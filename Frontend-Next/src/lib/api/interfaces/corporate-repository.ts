import type { CorporateSnapshot } from "@/types/corporate";

export interface CorporateRepository {
  getSnapshot(): Promise<CorporateSnapshot>;
}

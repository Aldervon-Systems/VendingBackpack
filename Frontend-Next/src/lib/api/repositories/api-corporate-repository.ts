"use client";

import { apiRequest } from "@/lib/api/api-client";
import type { CorporateRepository } from "@/lib/api/interfaces/corporate-repository";
import type { CorporateSnapshot } from "@/types/corporate";

export class ApiCorporateRepository implements CorporateRepository {
  async getSnapshot(): Promise<CorporateSnapshot> {
    return apiRequest<CorporateSnapshot>("/corporate", { method: "GET" });
  }
}

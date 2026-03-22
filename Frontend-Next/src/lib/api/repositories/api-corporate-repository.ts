"use client";

import { apiRequest } from "@/lib/api/api-client";
import type { CorporateRepository } from "@/lib/api/interfaces/corporate-repository";
import type { CorporateSnapshot, CorporateViewPreferences } from "@/types/corporate";

export class ApiCorporateRepository implements CorporateRepository {
  async getSnapshot(): Promise<CorporateSnapshot> {
    return apiRequest<CorporateSnapshot>("/corporate", { method: "GET" });
  }

  async getPreferences(): Promise<CorporateViewPreferences> {
    return apiRequest<CorporateViewPreferences>("/corporate/preferences", { method: "GET" });
  }

  async savePreferences(preferences: CorporateViewPreferences): Promise<CorporateViewPreferences> {
    return apiRequest<CorporateViewPreferences>("/corporate/preferences", {
      method: "PUT",
      body: preferences,
    });
  }
}

"use client";

import { useEffect, useState } from "react";

export type OnboardingDraft = {
  managerEmail: string;
  managerPassword: string;
  organizationName: string;
  adminPassword: string;
  whitelist: string[];
  organizationId: string | null;
  totpSeed: string;
  totpUri: string;
};

const STORAGE_KEY = "vb.next.onboarding-draft";

const DEFAULT_DRAFT: OnboardingDraft = {
  managerEmail: "renee@aldervon.com",
  managerPassword: "password123",
  organizationName: "Aldervon Systems",
  adminPassword: "admin",
  whitelist: ["ops@aldervon.com", "warehouse@aldervon.com"],
  organizationId: null,
  totpSeed: "",
  totpUri: "",
};

function readDraft() {
  if (typeof window === "undefined") {
    return DEFAULT_DRAFT;
  }

  const raw = window.sessionStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return DEFAULT_DRAFT;
  }

  try {
    const parsed = JSON.parse(raw) as Partial<OnboardingDraft>;
    return {
      ...DEFAULT_DRAFT,
      ...parsed,
      whitelist: Array.isArray(parsed.whitelist) ? parsed.whitelist.filter((item) => typeof item === "string") : DEFAULT_DRAFT.whitelist,
    };
  } catch {
    return DEFAULT_DRAFT;
  }
}

export function useOnboardingDraft() {
  const [draft, setDraft] = useState<OnboardingDraft>(readDraft);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }

    window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(draft));
  }, [draft]);

  function resetDraft() {
    setDraft(DEFAULT_DRAFT);
    if (typeof window !== "undefined") {
      window.sessionStorage.removeItem(STORAGE_KEY);
    }
  }

  return {
    draft,
    setDraft,
    resetDraft,
  };
}

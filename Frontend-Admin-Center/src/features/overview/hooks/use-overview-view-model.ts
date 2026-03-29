"use client";

import { useMemo } from "react";
import { LocalOverviewRepository } from "@/features/overview/lib/local-overview-repository";

const overviewRepository = new LocalOverviewRepository();

export function useOverviewViewModel() {
  return useMemo(() => overviewRepository.getOverview(), []);
}

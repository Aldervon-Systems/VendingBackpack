import { MACHINE_CONFIG_RECORDS, type MachineConfigRecord } from "@/features/machine-config/lib/mock-machine-config-data";
import {
  buildMachineSummary,
  buildValidationIssues,
  cloneRows,
  normalizeRows,
} from "@/features/machine-config/lib/machine-config-utils";
import type { MachineConfigDetail, MachineConfigRow, MachineConfigSummary, PublishRecord } from "@/features/machine-config/lib/types";

const store: MachineConfigRecord[] = JSON.parse(JSON.stringify(MACHINE_CONFIG_RECORDS)) as MachineConfigRecord[];

function cloneHistory(history: PublishRecord[]) {
  return JSON.parse(JSON.stringify(history)) as PublishRecord[];
}

function detailFromRecord(record: MachineConfigRecord): MachineConfigDetail {
  const publishedRows = cloneRows(record.publishedRows);
  const draftRows = cloneRows(record.draftRows);
  const validationIssues = buildValidationIssues(draftRows);

  return {
    summary: buildMachineSummary(
      record.metadata,
      draftRows,
      publishedRows,
      validationIssues,
      record.publishedAt,
      record.draftUpdatedAt,
    ),
    metadata: { ...record.metadata },
    backendState: "Mock Ready",
    publishedVersion: record.publishedVersion,
    publishedRows,
    draftRows,
    validationIssues,
    history: cloneHistory(record.history),
  };
}

function nowLabel() {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    timeZoneName: "short",
  }).format(new Date());
}

function nextVersion(version: string) {
  const match = version.match(/^v(\d+)\.(\d+)$/);
  if (!match) {
    return "v1.0";
  }

  const major = Number.parseInt(match[1], 10);
  const minor = Number.parseInt(match[2], 10) + 1;
  return `v${major}.${minor}`;
}

export class MockMachineConfigRepository {
  async listMachines(): Promise<MachineConfigSummary[]> {
    return store.map((record) => detailFromRecord(record).summary);
  }

  async getMachineConfig(machineId: string): Promise<MachineConfigDetail> {
    const record = store.find((candidate) => candidate.metadata.id === machineId);

    if (!record) {
      throw new Error("Machine configuration record not found");
    }

    return detailFromRecord(record);
  }

  async saveDraft(machineId: string, rows: MachineConfigRow[]): Promise<MachineConfigDetail> {
    const record = store.find((candidate) => candidate.metadata.id === machineId);

    if (!record) {
      throw new Error("Machine configuration record not found");
    }

    record.draftRows = normalizeRows(rows);
    record.draftUpdatedAt = nowLabel();
    record.history = [
      {
        id: `draft-${Date.now()}`,
        action: "Draft Saved",
        actor: "Current admin",
        timestamp: record.draftUpdatedAt,
        detail: "Saved machine layout and serial mapping draft from the admin control plane.",
      },
      ...record.history,
    ];

    return detailFromRecord(record);
  }

  async resetDraft(machineId: string): Promise<MachineConfigDetail> {
    const record = store.find((candidate) => candidate.metadata.id === machineId);

    if (!record) {
      throw new Error("Machine configuration record not found");
    }

    record.draftRows = cloneRows(record.publishedRows);
    record.draftUpdatedAt = nowLabel();
    return detailFromRecord(record);
  }

  async publishDraft(machineId: string, rows: MachineConfigRow[]): Promise<MachineConfigDetail> {
    const record = store.find((candidate) => candidate.metadata.id === machineId);

    if (!record) {
      throw new Error("Machine configuration record not found");
    }

    const publishedRows = normalizeRows(rows);
    record.draftRows = cloneRows(publishedRows);
    record.publishedRows = publishedRows;
    record.publishedAt = nowLabel();
    record.draftUpdatedAt = record.publishedAt;
    record.publishedVersion = nextVersion(record.publishedVersion);
    record.history = [
      {
        id: `publish-${Date.now()}`,
        action: "Published",
        actor: "Current admin",
        timestamp: record.publishedAt,
        detail: `Published ${record.metadata.name} into the ready-to-wire machine configuration channel.`,
      },
      ...record.history,
    ];

    return detailFromRecord(record);
  }
}

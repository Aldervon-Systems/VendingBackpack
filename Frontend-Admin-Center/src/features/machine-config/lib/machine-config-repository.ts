import type { MachineConfigDetail, MachineConfigRow, MachineConfigSummary } from "@/features/machine-config/lib/types";

export interface MachineConfigRepository {
  listMachines(): Promise<MachineConfigSummary[]>;
  getMachineConfig(machineId: string): Promise<MachineConfigDetail>;
  saveDraft(machineId: string, rows: MachineConfigRow[]): Promise<MachineConfigDetail>;
  resetDraft(machineId: string): Promise<MachineConfigDetail>;
  publishDraft(machineId: string, rows: MachineConfigRow[]): Promise<MachineConfigDetail>;
}

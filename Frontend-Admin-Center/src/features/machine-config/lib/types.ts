export type MachineConfigStatus = "Healthy" | "Draft" | "Mismatch" | "Needs Review";

export type MachineConfigTabId = "summary" | "layout" | "serial" | "validation" | "history";

export type SlotStatus = "configured" | "empty" | "mismatch" | "review";

export type ValidationSeverity = "critical" | "warning" | "info";

export type MachineConfigSlot = {
  id: string;
  rowId: string;
  code: string;
  sku: string;
  itemName: string;
  capacity: number;
  parLevel: number;
  serialChannel: string;
  actualSku: string;
  actualQuantity: number;
  status: SlotStatus;
  note: string;
};

export type MachineConfigRow = {
  id: string;
  label: string;
  slots: MachineConfigSlot[];
};

export type MachineConfigSummary = {
  id: string;
  name: string;
  organization: string;
  location: string;
  model: string;
  status: MachineConfigStatus;
  lastPublishedAt: string;
  draftUpdatedAt: string;
  slotCount: number;
  configuredCount: number;
  mismatchCount: number;
  serialCoverage: number;
  note: string;
};

export type MachineMetadata = {
  id: string;
  name: string;
  organization: string;
  location: string;
  model: string;
  serialProvider: string;
  hardwareProfile: string;
  lastAuditBy: string;
  lastAuditAt: string;
  note: string;
};

export type ValidationIssue = {
  id: string;
  severity: ValidationSeverity;
  title: string;
  detail: string;
  slotCode?: string;
};

export type PublishRecord = {
  id: string;
  action: "Published" | "Draft Saved" | "Imported" | "Reviewed";
  actor: string;
  timestamp: string;
  detail: string;
};

export type MachineConfigDetail = {
  summary: MachineConfigSummary;
  metadata: MachineMetadata;
  backendState: "Ready";
  publishedVersion: string;
  publishedRows: MachineConfigRow[];
  draftRows: MachineConfigRow[];
  validationIssues: ValidationIssue[];
  history: PublishRecord[];
};

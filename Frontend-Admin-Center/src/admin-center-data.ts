export type AdminTabId = "overview" | "organizations" | "access" | "fleet" | "incidents" | "broadcasts";

export type AdminProfile = {
  email: string;
  name: string;
  title: string;
  clearance: string;
  shift: string;
  lastActive: string;
  scope: string;
};

export type OrganizationRecord = {
  name: string;
  region: string;
  plan: string;
  health: "Healthy" | "Watch" | "Escalated" | "Review" | "Launching";
  machines: number;
  admins: number;
  billing: string;
  nextAction: string;
};

export type ApprovalRequest = {
  name: string;
  organization: string;
  scope: string;
  age: string;
  sponsor: string;
};

export type MachineAlert = {
  name: string;
  organization: string;
  site: string;
  status: "Healthy" | "Watch" | "Offline" | "Maintenance";
  firmware: string;
  heartbeat: string;
  nextAction: string;
};

export type IncidentRecord = {
  title: string;
  severity: "Critical" | "High" | "Medium";
  organization: string;
  owner: string;
  eta: string;
  impact: string;
  note: string;
};

export type BroadcastRecord = {
  title: string;
  audience: string;
  state: string;
  sendAt: string;
  body: string;
};

export const DEMO_PASSPHRASE = "AldervonOps!";

export const NAV_ITEMS: Array<{
  id: AdminTabId;
  label: string;
  count: string;
  eyebrow: string;
  title: string;
  description: string;
}> = [
  {
    id: "overview",
    label: "Overview",
    count: "18",
    eyebrow: "Platform posture",
    title: "Admin center for cross-tenant operations",
    description:
      "Monitor organizations, keep admin access in policy, resolve fleet incidents, and publish operator communications without mixing those actions into the manager workspace.",
  },
  {
    id: "organizations",
    label: "Organizations",
    count: "18",
    eyebrow: "Tenant portfolio",
    title: "Tenant organizations and launch posture",
    description:
      "Track health, billing pressure, admin coverage, and onboarding blockers across every organization attached to the platform.",
  },
  {
    id: "access",
    label: "Access",
    count: "07",
    eyebrow: "Identity and policy",
    title: "Admin access review and approval flow",
    description:
      "Approve elevated requests, keep privileged coverage balanced, and make sure every admin session remains within policy and audit scope.",
  },
  {
    id: "fleet",
    label: "Fleet",
    count: "246",
    eyebrow: "Machine command",
    title: "Fleet control across organizations",
    description:
      "Review heartbeat drift, firmware ring exposure, and machine escalations that cannot be handled inside a single tenant shell.",
  },
  {
    id: "incidents",
    label: "Incidents",
    count: "06",
    eyebrow: "Response queue",
    title: "Incident command and recovery ownership",
    description:
      "Run the platform incident queue, assign responders, and keep organization-facing updates accurate while outages or fraud checks are in motion.",
  },
  {
    id: "broadcasts",
    label: "Broadcasts",
    count: "03",
    eyebrow: "Communications",
    title: "Broadcasts, release notes, and launch notices",
    description:
      "Draft the messages that go to tenant admins, managers, and operator leads when platform policy or fleet posture changes.",
  },
];

export const ADMIN_PROFILES: AdminProfile[] = [
  {
    email: "ops.admin@aldervon.com",
    name: "Morgan Sloane",
    title: "Platform Operations Lead",
    clearance: "Global Write",
    shift: "Morning command",
    lastActive: "10:12 ET",
    scope: "Organizations, fleet, broadcasts",
  },
  {
    email: "ivy.chen@aldervon.com",
    name: "Ivy Chen",
    title: "Super Admin",
    clearance: "Root Oversight",
    shift: "Executive escalation",
    lastActive: "09:34 ET",
    scope: "Security, tenancy, release gates",
  },
  {
    email: "nina.patel@aldervon.com",
    name: "Nina Patel",
    title: "Risk and Access Admin",
    clearance: "Policy + Access",
    shift: "Identity review",
    lastActive: "08:57 ET",
    scope: "Access approvals, compliance, impersonation locks",
  },
  {
    email: "marcus.reed@aldervon.com",
    name: "Marcus Reed",
    title: "Fleet Reliability Admin",
    clearance: "Fleet Escalation",
    shift: "Field recovery",
    lastActive: "10:04 ET",
    scope: "Machine incidents, rollout holds, dispatch",
  },
];

export const OVERVIEW_METRICS = [
  { value: "18", label: "Active organizations", meta: "15 healthy, 2 watch, 1 escalated" },
  { value: "246", label: "Machines monitored", meta: "98.4% reporting inside the last 15 minutes" },
  { value: "47", label: "Admin operators", meta: "7 approvals pending before end of day" },
  { value: "06", label: "Open incidents", meta: "1 critical, 2 high, 3 medium" },
];

export const PRIORITY_QUEUE = [
  {
    title: "North Pier Foods",
    copy: "Three machines are offline in the Boston harbor district. Route fallback and dispatch reassignment are both required before lunch traffic.",
    tags: ["Critical recovery", "Fleet write required"],
  },
  {
    title: "Harbor Point Coffee",
    copy: "Billing retry enters the final grace window at 18:00 ET. Tenant admin has not acknowledged the renewal notice yet.",
    tags: ["Commercial watch", "Customer follow-up"],
  },
  {
    title: "Summit Health",
    copy: "Security review is the only blocker remaining before first-live launch. Access policy sign-off is still missing from legal.",
    tags: ["Launch blocker", "Policy review"],
  },
];

export const RELEASE_RINGS = [
  { title: "Canary ring", copy: "2 organizations on firmware 4.2.0 with manual rollback armed.", tone: "accent" },
  { title: "Standard ring", copy: "11 organizations on firmware 4.1.8. No blocking regressions reported today.", tone: "success" },
  { title: "Hold ring", copy: "5 organizations paused due to payment recovery, hardware swap, or launch readiness.", tone: "signal" },
];

export const RECENT_ACTIONS = [
  { title: "10:12 ET", copy: "Morgan Sloane moved Harbor Point Coffee to watch status and opened a renewal follow-up." },
  { title: "09:48 ET", copy: "Ivy Chen paused firmware ring promotion for North Pier Foods until dispatch confirms kiosk recovery." },
  { title: "08:57 ET", copy: "Nina Patel approved read-only audit access for Blue Harbor Markets legal review." },
];

export const GUARDRAILS = [
  {
    title: "Manager traffic stays in Frontend-Next",
    copy: "Platform admins work here. Tenant managers and field staff remain in the main operations app.",
  },
  {
    title: "Elevated changes require an approved admin account",
    copy: "This shell is restricted to the published admin roster and uses a separate sign-in from manager sessions.",
  },
  {
    title: "Broadcasts are platform-scoped",
    copy: "Messages authored here target admins, managers, or all operator leads across multiple organizations.",
  },
];

export const ORGANIZATIONS: OrganizationRecord[] = [
  {
    name: "Aldervon Systems",
    region: "Boston / Northeast",
    plan: "Enterprise",
    health: "Healthy",
    machines: 42,
    admins: 7,
    billing: "Paid through Apr 30",
    nextAction: "Review quarterly access roster",
  },
  {
    name: "Harbor Point Coffee",
    region: "Providence / Coastal",
    plan: "Growth",
    health: "Watch",
    machines: 18,
    admins: 3,
    billing: "Retry scheduled for 18:00 ET",
    nextAction: "Confirm renewal and keep release ring paused",
  },
  {
    name: "North Pier Foods",
    region: "Boston Harbor",
    plan: "Enterprise",
    health: "Escalated",
    machines: 11,
    admins: 2,
    billing: "Paid through Jun 15",
    nextAction: "Dispatch field recovery and approve backup route map",
  },
  {
    name: "Metro Campus Retail",
    region: "Cambridge / University",
    plan: "Launch",
    health: "Review",
    machines: 6,
    admins: 1,
    billing: "Contract pending signature",
    nextAction: "Approve whitelist and confirm launch checklist owner",
  },
  {
    name: "Southline Hotels",
    region: "Mid-Atlantic",
    plan: "Growth",
    health: "Healthy",
    machines: 23,
    admins: 4,
    billing: "Paid through May 22",
    nextAction: "Schedule firmware ring 2 after housekeeping pilot",
  },
  {
    name: "Kepler Hospitality",
    region: "New Jersey",
    plan: "Launch",
    health: "Launching",
    machines: 9,
    admins: 2,
    billing: "Waiting on go-live invoice",
    nextAction: "Collect legal contact and tenant DNS confirmation",
  },
];

export const ONBOARDING_QUEUE = [
  {
    title: "Kepler Hospitality",
    copy: "Waiting on legal contact, finance handoff, and first admin MFA enrollment.",
  },
  {
    title: "Summit Health",
    copy: "Compliance approval outstanding. Launch deck is ready once policy scope is signed.",
  },
  {
    title: "Blue Harbor Markets",
    copy: "DNS cutover window requested for Monday at 07:30 ET before device activation.",
  },
];

export const APPROVAL_REQUESTS: ApprovalRequest[] = [
  {
    name: "Jalen Price",
    organization: "Metro Campus Retail",
    scope: "Tenant launch admin",
    age: "22 minutes",
    sponsor: "Morgan Sloane",
  },
  {
    name: "Erica Vaughn",
    organization: "Harbor Point Coffee",
    scope: "Emergency fleet write",
    age: "48 minutes",
    sponsor: "Marcus Reed",
  },
  {
    name: "Luis Ortega",
    organization: "Blue Harbor Markets",
    scope: "Read-only finance audit",
    age: "1 hour 12 minutes",
    sponsor: "Nina Patel",
  },
];

export const ACCESS_POLICIES = [
  {
    title: "MFA is mandatory for every admin session",
    copy: "No admin account can enter the workspace without a registered second factor on the current device roster.",
  },
  {
    title: "Global write is restricted to platform operators",
    copy: "Tenant-specific admins cannot push fleet-wide changes or approve org-level impersonation requests from this shell.",
  },
  {
    title: "Session review happens every eight hours",
    copy: "Long-running operator sessions must re-authenticate before additional release or access approvals are accepted.",
  },
];

export const MACHINE_ALERTS: MachineAlert[] = [
  {
    name: "UNIT-BOS-014",
    organization: "North Pier Foods",
    site: "Harbor District",
    status: "Offline",
    firmware: "4.1.8",
    heartbeat: "19 minutes ago",
    nextAction: "Dispatch field recovery and hold route refill",
  },
  {
    name: "UNIT-PRV-007",
    organization: "Harbor Point Coffee",
    site: "Providence Station",
    status: "Watch",
    firmware: "4.2.0",
    heartbeat: "6 minutes ago",
    nextAction: "Pause canary ring until payment retry completes",
  },
  {
    name: "UNIT-CAM-003",
    organization: "Metro Campus Retail",
    site: "Student Center",
    status: "Maintenance",
    firmware: "4.1.8",
    heartbeat: "2 minutes ago",
    nextAction: "Replace card reader before launch readiness review",
  },
  {
    name: "UNIT-BHX-019",
    organization: "Aldervon Systems",
    site: "Assembly Annex",
    status: "Healthy",
    firmware: "4.2.0",
    heartbeat: "35 seconds ago",
    nextAction: "Eligible for ring-wide promotion when canary clears",
  },
];

export const INCIDENTS: IncidentRecord[] = [
  {
    title: "North Pier Foods fleet outage",
    severity: "Critical",
    organization: "North Pier Foods",
    owner: "Marcus Reed",
    eta: "Recovery plan due in 14 minutes",
    impact: "3 machines offline, lunchtime revenue at risk",
    note: "Route fallback is staged. Waiting on field dispatch confirmation before customer notice expands.",
  },
  {
    title: "Harbor Point renewal warning",
    severity: "High",
    organization: "Harbor Point Coffee",
    owner: "Morgan Sloane",
    eta: "Commercial follow-up today",
    impact: "Potential ring freeze and access downgrade if payment fails",
    note: "Broadcast draft is ready in case tenant admins need a release hold explanation.",
  },
  {
    title: "Summit Health compliance hold",
    severity: "Medium",
    organization: "Summit Health",
    owner: "Nina Patel",
    eta: "Legal review tomorrow 09:00 ET",
    impact: "Launch cannot proceed until security scope is approved",
    note: "All launch assets are staged. Remaining blocker is policy approval.",
  },
];

export const PLAYBOOK = [
  {
    title: "1. Stabilize tenant-facing impact",
    copy: "Pause ring movement, preserve operator trust, and make sure manager traffic still stays in the main app.",
  },
  {
    title: "2. Assign a single owner",
    copy: "Every incident card needs one named responder with a target time for the next update.",
  },
  {
    title: "3. Publish the next message before the next surprise",
    copy: "Use the broadcast tab to tell tenant admins what changed and what the next review window will be.",
  },
];

export const SCHEDULED_BROADCASTS: BroadcastRecord[] = [
  {
    title: "Firmware ring 2 readiness note",
    audience: "Tenant admins",
    state: "Scheduled",
    sendAt: "Today, 16:30 ET",
    body: "Firmware ring 2 is ready for the next cohort once Harbor Point Coffee clears billing watch and North Pier Foods exits dispatch recovery.",
  },
  {
    title: "Launch checklist reminder",
    audience: "Launching organizations",
    state: "Draft",
    sendAt: "Tomorrow, 09:00 ET",
    body: "Complete whitelist review, MFA enrollment, and incident escalation ownership before requesting launch approval.",
  },
  {
    title: "Weekend maintenance window",
    audience: "All operator leads",
    state: "Sent",
    sendAt: "Mar 20, 18:00 ET",
    body: "Manager traffic will remain in Frontend-Next while platform operators validate fleet telemetry and rollback windows.",
  },
];

export function findAdminProfile(email: string): AdminProfile | null {
  return ADMIN_PROFILES.find((profile) => profile.email === email.toLowerCase()) ?? null;
}

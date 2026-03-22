import type {
  AddMachinePayload,
  CreateOrganizationPayload,
  CreateOrganizationResponse,
  AuthCredentials,
  OrganizationSummary,
  SessionState,
  SignupPayload,
  UserRole,
  VerifyAdminPayload,
} from "@/types/auth";

export interface AuthRepository {
  restoreSession(): Promise<SessionState | null>;
  login(credentials: AuthCredentials): Promise<SessionState>;
  signup(payload: SignupPayload): Promise<SessionState>;
  logout(): Promise<void>;
  setRoleOverride(role: UserRole | null): Promise<SessionState | null>;
  searchOrganizations(query: string): Promise<OrganizationSummary[]>;
  createOrganization(payload: CreateOrganizationPayload): Promise<CreateOrganizationResponse>;
  verifyAdmin(payload: VerifyAdminPayload): Promise<boolean>;
  updateWhitelist(organizationId: string, emails: string[]): Promise<void>;
  addMachine(payload: AddMachinePayload): Promise<void>;
}

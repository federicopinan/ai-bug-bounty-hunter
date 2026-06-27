export type Severity = 'Critical' | 'High' | 'Medium' | 'Low' | 'Info';

export const SEVERITY_ORDER: Severity[] = ['Critical', 'High', 'Medium', 'Low', 'Info'];

export type FindingStatus =
  | 'NEW'
  | 'VALIDATED'
  | 'REPORTED'
  | 'DUPLICATE'
  | 'CLOSED'
  | 'RESOLVED'
  | 'INVALID';

export const ALL_STATUSES: FindingStatus[] = [
  'NEW',
  'VALIDATED',
  'REPORTED',
  'DUPLICATE',
  'CLOSED',
  'RESOLVED',
  'INVALID',
];

export interface Finding {
  id: string;
  target: string;
  severity: Severity;
  type: string;
  title: string;
  status: FindingStatus;
  endpoint?: string;
  bounty?: string;
  foundDate?: string;
  reportedDate?: string;
  platformId?: string;
  pocPaths: string[];
  sourceFile: string;
}

export interface ReconCounts {
  subdomains: number;
  liveHosts: number;
  ports: number;
  techStack: number;
  endpoints: number;
  jsFiles: number;
  wayback: number;
}

export interface ProgramSummary {
  target: string;
  scopePath: string;
  hasTracker: boolean;
  hasNotes: boolean;
  hasScope: boolean;
  program?: string;
  started?: string;
  scopeUrl?: string;
  recon: ReconCounts;
  findingsCount: number;
  findingsByStatus: Record<FindingStatus, number>;
  findingsBySeverity: Record<Severity, number>;
  lastActivity: string | null;
  lastActivityRel: string | null;
  scopeGuard: ScopeGuardSummary;
}

export interface ProgramDetail extends ProgramSummary {
  findings: Finding[];
  reconFiles: Array<{ name: string; size: number; lines: number; mtime: string }>;
  evidenceVaults: EvidenceVaultSummary[];
}

export interface ScopeGuardSummary {
  available: boolean;
  path: string;
  policyUrl?: string;
  allowedActions: string[];
  inScopeRules: number;
  outOfScopeRules: number;
  error?: string;
}

export interface EvidenceVaultSummary {
  findingId: string;
  path: string;
  evidenceCount: number;
  title?: string;
  severity?: string;
  type?: string;
}

export type ActivityKind = 'event' | 'recon' | 'finding' | 'note' | 'screenshot' | 'poc' | 'report' | 'scope' | 'other';

export interface FlightRecorderEvent {
  id: string;
  target: string;
  phase: string;
  action: string;
  status: string;
  message: string;
  timestamp: string;
  startedAt?: string;
  endedAt?: string;
  command?: string;
  outputPath?: string;
  metadata: Record<string, unknown>;
}

export interface ActivityEvent {
  source: 'flight-recorder' | 'file-mtime';
  target: string;
  kind: ActivityKind;
  path?: string;
  mtime: string;
  relTime: string;
  event?: FlightRecorderEvent;
}

export interface DashboardStats {
  totalPrograms: number;
  totalFindings: number;
  findingsByStatus: Record<FindingStatus, number>;
  findingsBySeverity: Record<Severity, number>;
  reportedBountyUsd: number;
  reportedCount: number;
  lastActivityAt: string | null;
}

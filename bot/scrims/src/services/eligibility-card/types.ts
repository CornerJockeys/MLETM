export type FranchiseStaffRole = 'GM' | 'AGM' | 'CAPT' | null;

export interface RawEligibilityCardData {
  schemaVersion?: number;
  tmid: string;
  accountId?: string | null;
  mleName: string;
  tmName: string;
  team: string;
  division: string;
  salary?: number | string | null;
  status?: string | null;
  scrimPoints?: number | null;
  scrimPointsRequired?: number | null;
  franchiseStaff?: FranchiseStaffRole;
  seasonEntry?: string | null;
  teamLogoKey?: string | null;
  teamFrameKey?: string | null;
  divisionStampKey?: string | null;
  seasonStampKey?: string | null;
  staffStampKey?: string | null;
}

export interface EligibilityCardData {
  schemaVersion: 1;
  tmid: string;
  accountId: string | null;
  mleName: string;
  tmName: string;
  team: string;
  division: string;
  salary: number;
  status: string;
  scrimPoints: number;
  scrimPointsRequired: number;
  franchiseStaff: FranchiseStaffRole;
  seasonEntry: string;
  teamLogoKey: string;
  teamFrameKey: string;
  divisionStampKey: string;
  seasonStampKey: string;
  staffStampKey: string | null;
}

export interface EligibilityCardAssetRefs {
  teamFrame: string;
  teamLogo: string;
  divisionStamp: string;
  seasonStamp: string;
  staffStamp: string | null;
}

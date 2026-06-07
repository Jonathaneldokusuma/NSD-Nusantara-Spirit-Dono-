export type Role =
  | "donatur"
  | "pemohon"
  | "konselor"
  | "operator"
  | "admin"
  | "super_admin";

export type CampaignStatus =
  | "draft"
  | "verifikasi"
  | "aktif"
  | "darurat"
  | "selesai"
  | "ditutup";

export interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: Role;
  passwordHash: string;
  verified: boolean;
  faith?: string;
  specialization?: string;
  available?: boolean;
  createdAt: string;
}

export interface Campaign {
  id: string;
  slug: string;
  title: string;
  summary: string;
  description: string;
  category: string;
  location: string;
  status: CampaignStatus;
  target: number;
  raised: number;
  distributed: number;
  donorCount: number;
  daysLeft: number;
  accent: string;
  icon: string;
  verified: boolean;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

export interface Donation {
  id: string;
  orderId: string;
  userId: string;
  campaignId: string;
  amount: number;
  method: "qris" | "va_bca" | "va_bni" | "va_mandiri";
  status: "pending" | "sukses" | "gagal" | "expired" | "refund";
  anonymous: boolean;
  message: string;
  paymentCode: string;
  createdAt: string;
  paidAt?: string;
}

export interface AidApplication {
  id: string;
  applicantId: string;
  title: string;
  category: string;
  location: string;
  amountNeeded: number;
  story: string;
  documents: string[];
  status:
    | "draf"
    | "diajukan"
    | "konseling"
    | "direkomendasikan"
    | "disetujui"
    | "ditolak"
    | "dipublikasikan";
  counselorId?: string;
  counselorNotes?: string;
  adminNotes?: string;
  campaignId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ChatMessage {
  id: string;
  senderId: string;
  text: string;
  createdAt: string;
}

export interface CounselingSession {
  id: string;
  userId: string;
  counselorId: string;
  applicationId?: string;
  topic: string;
  status: "menunggu" | "aktif" | "selesai";
  messages: ChatMessage[];
  createdAt: string;
  updatedAt: string;
}

export interface Disbursement {
  id: string;
  campaignId: string;
  date: string;
  recipient: string;
  description: string;
  amount: number;
  evidence: string;
  verifiedBy: string;
}

export interface Notification {
  id: string;
  userId: string;
  title: string;
  message: string;
  channel: "in_app" | "push" | "email" | "whatsapp";
  read: boolean;
  createdAt: string;
}

export interface NewsItem {
  id: string;
  title: string;
  excerpt: string;
  location: string;
  severity: "siaga" | "darurat" | "pemulihan";
  publishedAt: string;
}

export interface AuditLog {
  id: string;
  userId?: string;
  action: string;
  detail: string;
  ip: string;
  createdAt: string;
}

export interface Database {
  users: User[];
  campaigns: Campaign[];
  donations: Donation[];
  applications: AidApplication[];
  sessions: CounselingSession[];
  disbursements: Disbursement[];
  notifications: Notification[];
  news: NewsItem[];
  auditLogs: AuditLog[];
}

export interface SafeUser extends Omit<User, "passwordHash"> {}


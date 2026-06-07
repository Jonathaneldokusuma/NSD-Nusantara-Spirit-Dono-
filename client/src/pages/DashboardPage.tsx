import {
  Activity,
  ArrowRight,
  BadgeCheck,
  Banknote,
  Bell,
  BookOpenCheck,
  Check,
  ChevronRight,
  CircleDollarSign,
  ClipboardCheck,
  FileCheck2,
  HandHeart,
  HeartHandshake,
  Home,
  LayoutDashboard,
  LogOut,
  Menu,
  MessageCircleHeart,
  Plus,
  ReceiptText,
  Search,
  Send,
  Settings,
  ShieldCheck,
  UserCog,
  Users,
  WalletCards,
  X,
  type LucideIcon,
} from "lucide-react";
import {
  useEffect,
  useMemo,
  useState,
  type FormEvent,
  type ReactNode,
} from "react";
import { Link, Navigate } from "react-router-dom";
import { io } from "socket.io-client";
import { Logo, Modal, ProgressBar, Spinner, StatusBadge } from "../components/ui";
import { useAuth } from "../context/AuthContext";
import { api, patch, post } from "../lib/api";
import { roleLabel, rupiah, shortDate, statusLabel } from "../lib/format";
import type {
  AidApplication,
  Campaign,
  CounselingSession,
  Donation,
  Notification,
  PublicOverview,
  Role,
  User,
} from "../types";

type ViewKey =
  | "ringkasan"
  | "donasi"
  | "pengajuan"
  | "konseling"
  | "campaign"
  | "pengguna"
  | "audit"
  | "notifikasi"
  | "profil";

interface AdminOverview {
  totals: {
    users: number;
    campaigns: number;
    donations: number;
    successfulAmount: number;
    pendingApplications: number;
    activeSessions: number;
  };
  recentAudit: Array<{
    id: string;
    userId?: string;
    action: string;
    detail: string;
    ip: string;
    createdAt: string;
  }>;
}

const navigation: Array<{
  key: ViewKey;
  label: string;
  icon: LucideIcon;
  roles?: Role[];
}> = [
  { key: "ringkasan", label: "Ringkasan", icon: LayoutDashboard },
  {
    key: "donasi",
    label: "Riwayat Donasi",
    icon: ReceiptText,
    roles: ["donatur", "pemohon"],
  },
  {
    key: "pengajuan",
    label: "Pengajuan Bantuan",
    icon: ClipboardCheck,
    roles: ["pemohon", "donatur", "konselor", "operator", "admin", "super_admin"],
  },
  {
    key: "konseling",
    label: "Konseling",
    icon: MessageCircleHeart,
    roles: ["donatur", "pemohon", "konselor"],
  },
  {
    key: "campaign",
    label: "Kelola Campaign",
    icon: HandHeart,
    roles: ["operator", "admin", "super_admin"],
  },
  {
    key: "pengguna",
    label: "Kelola Pengguna",
    icon: Users,
    roles: ["admin", "super_admin"],
  },
  {
    key: "audit",
    label: "Audit Aktivitas",
    icon: ShieldCheck,
    roles: ["operator", "admin", "super_admin"],
  },
  { key: "notifikasi", label: "Notifikasi", icon: Bell },
  { key: "profil", label: "Profil & Keamanan", icon: Settings },
];

export function DashboardPage() {
  const { user, loading: authLoading, logout } = useAuth();
  const [activeView, setActiveView] = useState<ViewKey>("ringkasan");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [overview, setOverview] = useState<PublicOverview | null>(null);
  const [donations, setDonations] = useState<Donation[]>([]);
  const [applications, setApplications] = useState<AidApplication[]>([]);
  const [sessions, setSessions] = useState<CounselingSession[]>([]);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [counselors, setCounselors] = useState<User[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [adminOverview, setAdminOverview] = useState<AdminOverview | null>(null);

  async function loadData() {
    if (!user) return;
    const tasks: Promise<unknown>[] = [
      api<PublicOverview>("/public/overview").then(setOverview),
      api<Notification[]>("/notifications").then(setNotifications),
    ];

    if (["donatur", "pemohon"].includes(user.role)) {
      tasks.push(api<Donation[]>("/donations/mine").then(setDonations));
      tasks.push(api<AidApplication[]>("/applications/mine").then(setApplications));
      tasks.push(api<User[]>("/counselors").then(setCounselors));
    }
    if (["konselor", "operator", "admin", "super_admin"].includes(user.role)) {
      tasks.push(api<AidApplication[]>("/applications").then(setApplications));
      tasks.push(api<AdminOverview>("/admin/overview").then(setAdminOverview));
    }
    if (["donatur", "pemohon", "konselor"].includes(user.role)) {
      tasks.push(api<CounselingSession[]>("/sessions").then(setSessions));
    }
    if (["admin", "super_admin"].includes(user.role)) {
      tasks.push(api<User[]>("/admin/users").then(setUsers));
      tasks.push(api<User[]>("/counselors").then(setCounselors));
    }

    await Promise.allSettled(tasks);
    setLoading(false);
  }

  useEffect(() => {
    if (!user) return;
    void loadData();
    const socket = io({ path: "/socket.io" });
    const refresh = () => void loadData();
    socket.on("campaign.updated", refresh);
    socket.on("application.updated", refresh);
    socket.on("session.updated", refresh);
    socket.on("chat.message", refresh);
    return () => {
      socket.disconnect();
    };
  }, [user?.id]);

  if (authLoading) return <Spinner />;
  if (!user) return <Navigate to="/login?next=/app" replace />;

  const allowedNavigation = navigation.filter(
    (item) => !item.roles || item.roles.includes(user.role),
  );

  function chooseView(key: ViewKey) {
    setActiveView(key);
    setSidebarOpen(false);
  }

  return (
    <div className="dashboard-shell">
      <aside className={`dashboard-sidebar ${sidebarOpen ? "is-open" : ""}`}>
        <div className="sidebar-head">
          <Logo />
          <button onClick={() => setSidebarOpen(false)}>
            <X />
          </button>
        </div>
        <nav>
          <span className="sidebar-label">Menu utama</span>
          {allowedNavigation.map((item) => {
            const Icon = item.icon;
            return (
              <button
                className={activeView === item.key ? "active" : ""}
                onClick={() => chooseView(item.key)}
                key={item.key}
              >
                <Icon size={19} />
                {item.label}
                {item.key === "notifikasi" &&
                  notifications.some((entry) => !entry.read) && <i />}
              </button>
            );
          })}
        </nav>
        <div className="sidebar-public-link">
          <span>Halaman publik</span>
          <Link to="/">
            <Home size={18} /> Buka Beranda
          </Link>
          <Link to="/transparansi">
            <Activity size={18} /> Transparansi
          </Link>
        </div>
        <div className="sidebar-user">
          <span>{user.name.charAt(0)}</span>
          <div>
            <strong>{user.name}</strong>
            <small>{roleLabel(user.role)}</small>
          </div>
          <button onClick={logout} aria-label="Keluar">
            <LogOut size={18} />
          </button>
        </div>
      </aside>
      {sidebarOpen && (
        <button
          className="sidebar-overlay"
          aria-label="Tutup menu"
          onClick={() => setSidebarOpen(false)}
        />
      )}
      <main className="dashboard-main">
        <header className="dashboard-topbar">
          <button
            className="dashboard-menu-button"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu />
          </button>
          <div>
            <span>{roleLabel(user.role)}</span>
            <strong>{allowedNavigation.find((item) => item.key === activeView)?.label}</strong>
          </div>
          <div className="topbar-actions">
            <button
              className="icon-button"
              onClick={() => setActiveView("notifikasi")}
            >
              <Bell size={19} />
              {notifications.some((item) => !item.read) && <i />}
            </button>
            <span className="topbar-avatar">{user.name.charAt(0)}</span>
          </div>
        </header>
        <div className="dashboard-content">
          {loading ? (
            <Spinner />
          ) : (
            <>
              {activeView === "ringkasan" && (
                <OverviewView
                  user={user}
                  overview={overview}
                  donations={donations}
                  applications={applications}
                  adminOverview={adminOverview}
                  onNavigate={setActiveView}
                />
              )}
              {activeView === "donasi" && (
                <DonationsView donations={donations} />
              )}
              {activeView === "pengajuan" && (
                <ApplicationsView
                  user={user}
                  applications={applications}
                  counselors={counselors}
                  onRefresh={loadData}
                />
              )}
              {activeView === "konseling" && (
                <CounselingView
                  user={user}
                  sessions={sessions}
                  counselors={counselors}
                  onRefresh={loadData}
                />
              )}
              {activeView === "campaign" && overview && (
                <CampaignManagement
                  campaigns={overview.campaigns}
                  onRefresh={loadData}
                />
              )}
              {activeView === "pengguna" && (
                <UsersView users={users} currentUser={user} onRefresh={loadData} />
              )}
              {activeView === "audit" && (
                <AuditView adminOverview={adminOverview} />
              )}
              {activeView === "notifikasi" && (
                <NotificationsView
                  notifications={notifications}
                  onRefresh={loadData}
                />
              )}
              {activeView === "profil" && <ProfileView user={user} />}
            </>
          )}
        </div>
      </main>
    </div>
  );
}

function ViewHeading({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="view-heading">
      <div>
        <span className="eyebrow">{eyebrow}</span>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      {action}
    </div>
  );
}

function MetricCard({
  icon: Icon,
  label,
  value,
  note,
  tone = "green",
}: {
  icon: LucideIcon;
  label: string;
  value: string;
  note: string;
  tone?: string;
}) {
  return (
    <article className="dashboard-metric">
      <span className={`stat-icon ${tone}`}>
        <Icon />
      </span>
      <p>{label}</p>
      <strong>{value}</strong>
      <small>{note}</small>
    </article>
  );
}

function OverviewView({
  user,
  overview,
  donations,
  applications,
  adminOverview,
  onNavigate,
}: {
  user: User;
  overview: PublicOverview | null;
  donations: Donation[];
  applications: AidApplication[];
  adminOverview: AdminOverview | null;
  onNavigate: (view: ViewKey) => void;
}) {
  const isInternal = ["konselor", "operator", "admin", "super_admin"].includes(
    user.role,
  );
  const successfulDonations = donations.filter((item) => item.status === "sukses");
  const totalMine = successfulDonations.reduce((sum, item) => sum + item.amount, 0);

  return (
    <>
      <ViewHeading
        eyebrow={`Halo, ${user.name.split(" ")[0]}`}
        title={
          user.role === "pemohon"
            ? "Kami mendampingi proses bantuan Anda."
            : isInternal
              ? "Pantau operasi NSD dari satu tempat."
              : "Terima kasih sudah ikut menguatkan."
        }
        description={
          user.role === "pemohon"
            ? "Lihat status pengajuan, lengkapi verifikasi, dan lanjutkan komunikasi dengan konselor."
            : isInternal
              ? "Data di bawah diperbarui saat ada aktivitas campaign, pengajuan, atau konseling."
              : "Jelajahi kebutuhan terverifikasi dan pantau dampak bantuan Anda."
        }
        action={
          user.role === "pemohon" ? (
            <button
              className="button button-primary"
              onClick={() => onNavigate("pengajuan")}
            >
              <Plus size={17} /> Buat Pengajuan
            </button>
          ) : user.role === "donatur" ? (
            <Link className="button button-primary" to="/campaign">
              Donasi Lagi <ArrowRight size={17} />
            </Link>
          ) : undefined
        }
      />

      <div className="dashboard-metrics">
        {isInternal ? (
          <>
            <MetricCard
              icon={WalletCards}
              label="Donasi terkonfirmasi"
              value={rupiah(adminOverview?.totals.successfulAmount || 0, true)}
              note={`${adminOverview?.totals.donations || 0} transaksi tercatat`}
            />
            <MetricCard
              icon={ClipboardCheck}
              label="Menunggu verifikasi"
              value={String(adminOverview?.totals.pendingApplications || 0)}
              note="Pengajuan aktif"
              tone="gold"
            />
            <MetricCard
              icon={MessageCircleHeart}
              label="Sesi pendampingan"
              value={String(adminOverview?.totals.activeSessions || 0)}
              note="Sesi belum selesai"
              tone="blue"
            />
            <MetricCard
              icon={Users}
              label="Pengguna sistem"
              value={String(adminOverview?.totals.users || 0)}
              note={`${adminOverview?.totals.campaigns || 0} campaign dikelola`}
              tone="coral"
            />
          </>
        ) : (
          <>
            <MetricCard
              icon={HandHeart}
              label="Total bantuan Anda"
              value={rupiah(totalMine)}
              note={`${successfulDonations.length} donasi berhasil`}
            />
            <MetricCard
              icon={ReceiptText}
              label="Transaksi"
              value={String(donations.length)}
              note="Seluruh status donasi"
              tone="blue"
            />
            <MetricCard
              icon={HeartHandshake}
              label="Pengajuan bantuan"
              value={String(applications.length)}
              note={
                applications[0]
                  ? `Status: ${statusLabel(applications[0].status)}`
                  : "Belum ada pengajuan"
              }
              tone="gold"
            />
            <MetricCard
              icon={CircleDollarSign}
              label="Dampak komunitas"
              value={rupiah(overview?.stats.totalDistributed || 0, true)}
              note="Dana telah disalurkan"
              tone="coral"
            />
          </>
        )}
      </div>

      <div className="overview-grid">
        <article className="dashboard-panel">
          <div className="panel-head">
            <div>
              <span>{isInternal ? "Antrian kerja" : "Campaign pilihan"}</span>
              <h2>{isInternal ? "Pengajuan terbaru" : "Bantuan mendesak"}</h2>
            </div>
            <button
              className="text-link"
              onClick={() => onNavigate(isInternal ? "pengajuan" : "donasi")}
            >
              Lihat detail <ChevronRight size={16} />
            </button>
          </div>
          {isInternal ? (
            <div className="compact-list">
              {applications.slice(0, 4).map((application) => (
                <div key={application.id}>
                  <span className="list-avatar">
                    {application.applicant?.name?.charAt(0) || "P"}
                  </span>
                  <p>
                    <strong>{application.title}</strong>
                    <span>
                      {application.location} - {rupiah(application.amountNeeded)}
                    </span>
                  </p>
                  <span className={`status-badge status-${application.status}`}>
                    {statusLabel(application.status)}
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <div className="compact-campaigns">
              {overview?.campaigns.slice(0, 3).map((campaign) => (
                <Link to={`/campaign/${campaign.slug}`} key={campaign.id}>
                  <span
                    className="campaign-dot"
                    style={{ background: campaign.accent }}
                  />
                  <p>
                    <strong>{campaign.title}</strong>
                    <span>{campaign.location}</span>
                  </p>
                  <b>{Math.round((campaign.raised / campaign.target) * 100)}%</b>
                </Link>
              ))}
            </div>
          )}
        </article>
        <article className="dashboard-panel action-panel">
          <span className="eyebrow">Aksi cepat</span>
          <h2>Apa yang ingin Anda lakukan?</h2>
          <div className="quick-actions">
            {isInternal ? (
              <>
                <button onClick={() => onNavigate("pengajuan")}>
                  <ClipboardCheck /> Tinjau pengajuan
                </button>
                {["operator", "admin", "super_admin"].includes(user.role) && (
                  <button onClick={() => onNavigate("campaign")}>
                    <HandHeart /> Kelola campaign
                  </button>
                )}
                <button onClick={() => onNavigate("audit")}>
                  <ShieldCheck /> Lihat audit log
                </button>
              </>
            ) : (
              <>
                <Link to="/campaign">
                  <HandHeart /> Pilih campaign
                </Link>
                <button onClick={() => onNavigate("pengajuan")}>
                  <ClipboardCheck /> Ajukan bantuan
                </button>
                <button onClick={() => onNavigate("konseling")}>
                  <MessageCircleHeart /> Mulai konseling
                </button>
              </>
            )}
          </div>
        </article>
      </div>
    </>
  );
}

function DonationsView({ donations }: { donations: Donation[] }) {
  return (
    <>
      <ViewHeading
        eyebrow="Riwayat pribadi"
        title="Donasi dan status pembayaran"
        description="Seluruh transaksi tercatat bersama order ID dan status konfirmasinya."
        action={
          <Link className="button button-primary" to="/campaign">
            <Plus size={17} /> Donasi Baru
          </Link>
        }
      />
      <article className="dashboard-panel data-panel">
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Tanggal</th>
                <th>Campaign</th>
                <th>Order ID</th>
                <th>Metode</th>
                <th>Nominal</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {donations.map((donation) => (
                <tr key={donation.id}>
                  <td>{shortDate(donation.createdAt)}</td>
                  <td>
                    <strong>{donation.campaign?.title || donation.campaignId}</strong>
                  </td>
                  <td>
                    <code>{donation.orderId}</code>
                  </td>
                  <td>{donation.method.toUpperCase().replace("_", " ")}</td>
                  <td>{rupiah(donation.amount)}</td>
                  <td>
                    <StatusBadge status={donation.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {!donations.length && (
          <div className="empty-inline">
            Belum ada transaksi. Pilih campaign untuk mulai membantu.
          </div>
        )}
      </article>
    </>
  );
}

function ApplicationsView({
  user,
  applications,
  counselors,
  onRefresh,
}: {
  user: User;
  applications: AidApplication[];
  counselors: User[];
  onRefresh: () => Promise<void>;
}) {
  const [formOpen, setFormOpen] = useState(false);
  const [detail, setDetail] = useState<AidApplication | null>(null);
  const [busyId, setBusyId] = useState("");
  const canSubmit = ["pemohon", "donatur"].includes(user.role);
  const isCounselor = user.role === "konselor";
  const isAdmin = ["operator", "admin", "super_admin"].includes(user.role);

  async function updateApplication(id: string, body: unknown) {
    setBusyId(id);
    try {
      await patch(`/applications/${id}`, body);
      await onRefresh();
      setDetail(null);
    } finally {
      setBusyId("");
    }
  }

  return (
    <>
      <ViewHeading
        eyebrow={canSubmit ? "Permohonan bantuan" : "Verifikasi berlapis"}
        title={
          canSubmit ? "Pantau proses pengajuan Anda" : "Tinjau kebutuhan yang masuk"
        }
        description={
          canSubmit
            ? "Status bergerak dari pengajuan, konseling, rekomendasi, hingga publikasi campaign."
            : "Pastikan identitas, cerita, dokumen, dan rekomendasi konselor telah memadai."
        }
        action={
          canSubmit ? (
            <button
              className="button button-primary"
              onClick={() => setFormOpen(true)}
            >
              <Plus size={17} /> Ajukan Bantuan
            </button>
          ) : undefined
        }
      />
      <div className="application-grid">
        {applications.map((application) => (
          <article className="application-card" key={application.id}>
            <div className="application-card-head">
              <span className="application-icon">
                <HeartHandshake />
              </span>
              <StatusBadge status={application.status} />
            </div>
            <span className="eyebrow">{application.category}</span>
            <h3>{application.title}</h3>
            <p>{application.story.slice(0, 150)}...</p>
            <div className="application-meta">
              <span>{application.location}</span>
              <strong>{rupiah(application.amountNeeded)}</strong>
            </div>
            <div className="application-footer">
              <span>
                {application.counselor?.name ||
                  (application.counselorId ? "Konselor ditugaskan" : "Belum ada konselor")}
              </span>
              <button className="text-link" onClick={() => setDetail(application)}>
                Lihat detail <ChevronRight size={16} />
              </button>
            </div>
          </article>
        ))}
        {!applications.length && (
          <div className="dashboard-panel empty-inline">
            Belum ada pengajuan pada daftar ini.
          </div>
        )}
      </div>

      <ApplicationForm
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onCreated={async () => {
          setFormOpen(false);
          await onRefresh();
        }}
      />

      <Modal open={Boolean(detail)} onClose={() => setDetail(null)} size="large">
        {detail && (
          <div className="application-detail">
            <div className="modal-heading">
              <span className="eyebrow">{detail.category}</span>
              <h2>{detail.title}</h2>
              <p>{detail.location}</p>
            </div>
            <div className="application-detail-stats">
              <span>
                Kebutuhan <strong>{rupiah(detail.amountNeeded)}</strong>
              </span>
              <span>
                Status <StatusBadge status={detail.status} />
              </span>
              <span>
                Dokumen <strong>{detail.documents.length} item</strong>
              </span>
            </div>
            <h3>Cerita dan kebutuhan</h3>
            <p>{detail.story}</p>
            <h3>Dokumen pendukung</h3>
            <div className="document-chips">
              {detail.documents.map((document) => (
                <span key={document}>
                  <FileCheck2 size={16} /> {document}
                </span>
              ))}
            </div>
            {detail.counselorNotes && (
              <div className="verification-note">
                <BookOpenCheck />
                <div>
                  <strong>Catatan konselor</strong>
                  <p>{detail.counselorNotes}</p>
                </div>
              </div>
            )}
            <div className="modal-actions">
              {isCounselor && !detail.counselorId && (
                <button
                  className="button button-primary"
                  disabled={busyId === detail.id}
                  onClick={() =>
                    updateApplication(detail.id, {
                      counselorId: user.id,
                      status: "konseling",
                    })
                  }
                >
                  <MessageCircleHeart size={17} /> Ambil Pendampingan
                </button>
              )}
              {isCounselor &&
                detail.counselorId === user.id &&
                detail.status === "konseling" && (
                  <button
                    className="button button-primary"
                    disabled={busyId === detail.id}
                    onClick={() =>
                      updateApplication(detail.id, {
                        status: "direkomendasikan",
                        counselorNotes:
                          "Identitas, kondisi, dan kebutuhan telah dikonfirmasi melalui sesi konseling. Direkomendasikan untuk persetujuan admin.",
                      })
                    }
                  >
                    <BadgeCheck size={17} /> Beri Rekomendasi
                  </button>
                )}
              {isAdmin && !detail.counselorId && counselors[0] && (
                <button
                  className="button button-soft"
                  disabled={busyId === detail.id}
                  onClick={() =>
                    updateApplication(detail.id, {
                      counselorId: counselors[0].id,
                      status: "konseling",
                    })
                  }
                >
                  <UserCog size={17} /> Tugaskan {counselors[0].name}
                </button>
              )}
              {isAdmin && detail.status === "direkomendasikan" && (
                <button
                  className="button button-primary"
                  disabled={busyId === detail.id}
                  onClick={() =>
                    updateApplication(detail.id, {
                      status: "disetujui",
                      adminNotes:
                        "Disetujui untuk dibuat menjadi draft campaign terverifikasi.",
                    })
                  }
                >
                  <Check size={17} /> Setujui Pengajuan
                </button>
              )}
              {isAdmin &&
                !["ditolak", "disetujui", "dipublikasikan"].includes(
                  detail.status,
                ) && (
                  <button
                    className="button button-danger-soft"
                    disabled={busyId === detail.id}
                    onClick={() =>
                      updateApplication(detail.id, {
                        status: "ditolak",
                        adminNotes: "Pengajuan membutuhkan data tambahan.",
                      })
                    }
                  >
                    Tolak
                  </button>
                )}
            </div>
          </div>
        )}
      </Modal>
    </>
  );
}

function ApplicationForm({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: () => Promise<void>;
}) {
  const [form, setForm] = useState({
    title: "",
    category: "Bencana Alam",
    location: "",
    amountNeeded: 10_000_000,
    story: "",
    documents: "KTP, Foto kondisi, Surat keterangan",
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError("");
    try {
      await post("/applications", {
        ...form,
        documents: form.documents
          .split(",")
          .map((item) => item.trim())
          .filter(Boolean),
      });
      await onCreated();
      setForm({
        title: "",
        category: "Bencana Alam",
        location: "",
        amountNeeded: 10_000_000,
        story: "",
        documents: "KTP, Foto kondisi, Surat keterangan",
      });
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Pengajuan gagal.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal open={open} onClose={onClose} size="large">
      <form className="application-form" onSubmit={submit}>
        <div className="modal-heading">
          <span className="eyebrow">Pengajuan baru</span>
          <h2>Ceritakan bantuan yang dibutuhkan</h2>
          <p>Data akan ditinjau dan dilanjutkan melalui komunikasi konselor.</p>
        </div>
        <div className="form-grid">
          <label className="form-field span-two">
            <span>Judul kebutuhan</span>
            <input
              required
              minLength={8}
              value={form.title}
              onChange={(event) => setForm({ ...form, title: event.target.value })}
              placeholder="Contoh: Bantuan pemulihan rumah pascabanjir"
            />
          </label>
          <label className="form-field">
            <span>Kategori</span>
            <select
              value={form.category}
              onChange={(event) =>
                setForm({ ...form, category: event.target.value })
              }
            >
              <option>Bencana Alam</option>
              <option>Kesehatan</option>
              <option>Ekonomi</option>
              <option>Sosial</option>
            </select>
          </label>
          <label className="form-field">
            <span>Lokasi</span>
            <input
              required
              value={form.location}
              onChange={(event) =>
                setForm({ ...form, location: event.target.value })
              }
              placeholder="Kota/Kabupaten, Provinsi"
            />
          </label>
          <label className="form-field">
            <span>Target kebutuhan</span>
            <input
              type="number"
              min={100000}
              required
              value={form.amountNeeded}
              onChange={(event) =>
                setForm({ ...form, amountNeeded: Number(event.target.value) })
              }
            />
          </label>
          <label className="form-field">
            <span>Daftar dokumen, pisahkan dengan koma</span>
            <input
              required
              value={form.documents}
              onChange={(event) =>
                setForm({ ...form, documents: event.target.value })
              }
            />
          </label>
          <label className="form-field span-two">
            <span>Cerita kondisi dan rencana penggunaan dana</span>
            <textarea
              required
              minLength={50}
              value={form.story}
              onChange={(event) => setForm({ ...form, story: event.target.value })}
              placeholder="Jelaskan kondisi saat ini, dampak yang dialami, dan rencana penggunaan bantuan secara rinci."
            />
          </label>
        </div>
        {error && <div className="notice notice-error">{error}</div>}
        <div className="modal-actions">
          <button type="button" className="button button-ghost" onClick={onClose}>
            Batal
          </button>
          <button className="button button-primary" disabled={busy}>
            {busy ? "Mengirim..." : "Kirim Pengajuan"}
          </button>
        </div>
      </form>
    </Modal>
  );
}

function CounselingView({
  user,
  sessions,
  counselors,
  onRefresh,
}: {
  user: User;
  sessions: CounselingSession[];
  counselors: User[];
  onRefresh: () => Promise<void>;
}) {
  const [selectedId, setSelectedId] = useState(sessions[0]?.id || "");
  const [message, setMessage] = useState("");
  const [startOpen, setStartOpen] = useState(false);
  const [topic, setTopic] = useState("Pendampingan dan dukungan");
  const selected = sessions.find((session) => session.id === selectedId) || sessions[0];

  useEffect(() => {
    if (!selectedId && sessions[0]) setSelectedId(sessions[0].id);
  }, [sessions, selectedId]);

  async function sendMessage(event: FormEvent) {
    event.preventDefault();
    if (!selected || !message.trim()) return;
    await post(`/sessions/${selected.id}/messages`, { text: message.trim() });
    setMessage("");
    await onRefresh();
  }

  async function startSession(counselorId: string) {
    const session = await post<CounselingSession>("/sessions", {
      counselorId,
      topic,
    });
    setStartOpen(false);
    setSelectedId(session.id);
    await onRefresh();
  }

  return (
    <>
      <ViewHeading
        eyebrow="Pendampingan manusiawi"
        title={
          user.role === "konselor"
            ? "Sesi konseling yang Anda dampingi"
            : "Ruang komunikasi yang aman"
        }
        description="Pesan diperbarui secara real-time dan tersimpan sebagai bagian dari proses pendampingan."
        action={
          user.role !== "konselor" ? (
            <button
              className="button button-primary"
              onClick={() => setStartOpen(true)}
            >
              <Plus size={17} /> Mulai Sesi
            </button>
          ) : undefined
        }
      />
      <div className="chat-layout">
        <aside className="chat-list">
          <div className="chat-list-head">
            <strong>Daftar sesi</strong>
            <span>{sessions.length}</span>
          </div>
          {sessions.map((session) => {
            const counterpart =
              user.role === "konselor" ? session.user : session.counselor;
            return (
              <button
                className={selected?.id === session.id ? "active" : ""}
                onClick={() => setSelectedId(session.id)}
                key={session.id}
              >
                <span>{counterpart?.name.charAt(0)}</span>
                <p>
                  <strong>{counterpart?.name}</strong>
                  <small>{session.topic}</small>
                </p>
                <i className={`session-${session.status}`} />
              </button>
            );
          })}
          {!sessions.length && (
            <p className="chat-empty">Belum ada sesi konseling.</p>
          )}
        </aside>
        <section className="chat-panel">
          {selected ? (
            <>
              <header>
                <span>
                  {(user.role === "konselor"
                    ? selected.user.name
                    : selected.counselor.name
                  ).charAt(0)}
                </span>
                <div>
                  <strong>
                    {user.role === "konselor"
                      ? selected.user.name
                      : selected.counselor.name}
                  </strong>
                  <small>
                    {statusLabel(selected.status)} - {selected.topic}
                  </small>
                </div>
                <StatusBadge status={selected.status} />
              </header>
              <div className="chat-messages">
                {selected.messages.map((item) => {
                  const mine = item.senderId === user.id;
                  return (
                    <div className={mine ? "message mine" : "message"} key={item.id}>
                      <p>{item.text}</p>
                      <small>
                        {new Date(item.createdAt).toLocaleTimeString("id-ID", {
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </small>
                    </div>
                  );
                })}
                {!selected.messages.length && (
                  <div className="chat-welcome">
                    <MessageCircleHeart />
                    <strong>Mulai percakapan dengan empati.</strong>
                    <p>Pesan pertama akan mengaktifkan sesi ini.</p>
                  </div>
                )}
              </div>
              <form className="chat-compose" onSubmit={sendMessage}>
                <input
                  value={message}
                  onChange={(event) => setMessage(event.target.value)}
                  placeholder="Tulis pesan..."
                />
                <button disabled={!message.trim()}>
                  <Send size={19} />
                </button>
              </form>
            </>
          ) : (
            <div className="chat-placeholder">
              <MessageCircleHeart />
              <h3>Pilih atau mulai sesi konseling</h3>
              <p>Ruang percakapan akan tampil di sini.</p>
            </div>
          )}
        </section>
      </div>
      <Modal open={startOpen} onClose={() => setStartOpen(false)}>
        <div className="modal-heading">
          <span className="eyebrow">Sesi baru</span>
          <h2>Pilih konselor</h2>
          <p>Semua konselor telah diverifikasi oleh pengelola NSD.</p>
        </div>
        <label className="form-field">
          <span>Topik pendampingan</span>
          <input value={topic} onChange={(event) => setTopic(event.target.value)} />
        </label>
        <div className="counselor-list">
          {counselors.map((counselor) => (
            <button onClick={() => startSession(counselor.id)} key={counselor.id}>
              <span>{counselor.name.charAt(0)}</span>
              <p>
                <strong>{counselor.name}</strong>
                <small>
                  {counselor.faith} - {counselor.specialization}
                </small>
              </p>
              <BadgeCheck size={18} />
            </button>
          ))}
        </div>
      </Modal>
    </>
  );
}

function CampaignManagement({
  campaigns,
  onRefresh,
}: {
  campaigns: Campaign[];
  onRefresh: () => Promise<void>;
}) {
  const [createOpen, setCreateOpen] = useState(false);
  const [disburseOpen, setDisburseOpen] = useState<Campaign | null>(null);
  const [search, setSearch] = useState("");

  async function setStatus(campaign: Campaign, status: Campaign["status"]) {
    await patch(`/admin/campaigns/${campaign.id}`, { status });
    await onRefresh();
  }

  const filtered = campaigns.filter((campaign) =>
    [campaign.title, campaign.location, campaign.status]
      .join(" ")
      .toLowerCase()
      .includes(search.toLowerCase()),
  );

  return (
    <>
      <ViewHeading
        eyebrow="Operasional campaign"
        title="Kelola publikasi dan penyaluran"
        description="Aktifkan campaign yang sudah disetujui, ubah status lapangan, dan catat setiap penggunaan dana."
        action={
          <button
            className="button button-primary"
            onClick={() => setCreateOpen(true)}
          >
            <Plus size={17} /> Campaign Baru
          </button>
        }
      />
      <div className="panel-toolbar">
        <label className="search-field">
          <Search size={18} />
          <input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Cari campaign"
          />
        </label>
      </div>
      <div className="admin-campaign-list">
        {filtered.map((campaign) => (
          <article key={campaign.id}>
            <span
              className="campaign-admin-icon"
              style={{ background: `${campaign.accent}20`, color: campaign.accent }}
            >
              <HandHeart />
            </span>
            <div className="campaign-admin-main">
              <div>
                <StatusBadge status={campaign.status} />
                <small>{campaign.location}</small>
              </div>
              <h3>{campaign.title}</h3>
              <ProgressBar
                value={campaign.raised}
                target={campaign.target}
                color={campaign.accent}
              />
              <p>
                <strong>{rupiah(campaign.raised)}</strong> dari{" "}
                {rupiah(campaign.target)} - tersalur{" "}
                {rupiah(campaign.distributed)}
              </p>
            </div>
            <div className="campaign-admin-actions">
              {["draft", "verifikasi"].includes(campaign.status) && (
                <button
                  className="button button-primary button-small"
                  onClick={() => setStatus(campaign, "aktif")}
                >
                  Publikasikan
                </button>
              )}
              {campaign.status === "aktif" && (
                <button
                  className="button button-danger-soft button-small"
                  onClick={() => setStatus(campaign, "darurat")}
                >
                  Tandai Darurat
                </button>
              )}
              <button
                className="button button-soft button-small"
                onClick={() => setDisburseOpen(campaign)}
              >
                <Banknote size={15} /> Catat Penyaluran
              </button>
            </div>
          </article>
        ))}
      </div>
      <CampaignForm
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onCreated={async () => {
          setCreateOpen(false);
          await onRefresh();
        }}
      />
      <DisbursementForm
        campaign={disburseOpen}
        onClose={() => setDisburseOpen(null)}
        onCreated={async () => {
          setDisburseOpen(null);
          await onRefresh();
        }}
      />
    </>
  );
}

function CampaignForm({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: () => Promise<void>;
}) {
  const [form, setForm] = useState({
    title: "",
    summary: "",
    description: "",
    category: "Bencana Alam",
    location: "",
    target: 100_000_000,
    status: "draft",
    daysLeft: 30,
  });

  async function submit(event: FormEvent) {
    event.preventDefault();
    await post("/admin/campaigns", form);
    await onCreated();
  }

  return (
    <Modal open={open} onClose={onClose} size="large">
      <form className="application-form" onSubmit={submit}>
        <div className="modal-heading">
          <span className="eyebrow">Campaign baru</span>
          <h2>Siapkan informasi publik</h2>
        </div>
        <div className="form-grid">
          <label className="form-field span-two">
            <span>Judul campaign</span>
            <input
              required
              minLength={5}
              value={form.title}
              onChange={(event) => setForm({ ...form, title: event.target.value })}
            />
          </label>
          <label className="form-field">
            <span>Kategori</span>
            <input
              value={form.category}
              onChange={(event) =>
                setForm({ ...form, category: event.target.value })
              }
            />
          </label>
          <label className="form-field">
            <span>Lokasi</span>
            <input
              required
              value={form.location}
              onChange={(event) =>
                setForm({ ...form, location: event.target.value })
              }
            />
          </label>
          <label className="form-field">
            <span>Target dana</span>
            <input
              type="number"
              min={100000}
              value={form.target}
              onChange={(event) =>
                setForm({ ...form, target: Number(event.target.value) })
              }
            />
          </label>
          <label className="form-field">
            <span>Durasi (hari)</span>
            <input
              type="number"
              min={0}
              value={form.daysLeft}
              onChange={(event) =>
                setForm({ ...form, daysLeft: Number(event.target.value) })
              }
            />
          </label>
          <label className="form-field span-two">
            <span>Ringkasan</span>
            <input
              required
              minLength={10}
              value={form.summary}
              onChange={(event) =>
                setForm({ ...form, summary: event.target.value })
              }
            />
          </label>
          <label className="form-field span-two">
            <span>Deskripsi lengkap</span>
            <textarea
              required
              minLength={20}
              value={form.description}
              onChange={(event) =>
                setForm({ ...form, description: event.target.value })
              }
            />
          </label>
        </div>
        <div className="modal-actions">
          <button type="button" className="button button-ghost" onClick={onClose}>
            Batal
          </button>
          <button className="button button-primary">Simpan Draft</button>
        </div>
      </form>
    </Modal>
  );
}

function DisbursementForm({
  campaign,
  onClose,
  onCreated,
}: {
  campaign: Campaign | null;
  onClose: () => void;
  onCreated: () => Promise<void>;
}) {
  const [form, setForm] = useState({
    recipient: "",
    description: "",
    amount: 1_000_000,
    evidence: "",
  });

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!campaign) return;
    await post("/admin/disbursements", {
      campaignId: campaign.id,
      ...form,
    });
    await onCreated();
  }

  return (
    <Modal open={Boolean(campaign)} onClose={onClose}>
      {campaign && (
        <form onSubmit={submit}>
          <div className="modal-heading">
            <span className="eyebrow">Penyaluran dana</span>
            <h2>{campaign.title}</h2>
            <p>
              Saldo tersedia:{" "}
              <strong>{rupiah(campaign.raised - campaign.distributed)}</strong>
            </p>
          </div>
          <label className="form-field">
            <span>Penerima/posko</span>
            <input
              required
              value={form.recipient}
              onChange={(event) =>
                setForm({ ...form, recipient: event.target.value })
              }
            />
          </label>
          <label className="form-field">
            <span>Kegunaan dana</span>
            <input
              required
              value={form.description}
              onChange={(event) =>
                setForm({ ...form, description: event.target.value })
              }
            />
          </label>
          <label className="form-field">
            <span>Nominal</span>
            <input
              type="number"
              required
              min={1}
              max={campaign.raised - campaign.distributed}
              value={form.amount}
              onChange={(event) =>
                setForm({ ...form, amount: Number(event.target.value) })
              }
            />
          </label>
          <label className="form-field">
            <span>Bukti/dokumentasi</span>
            <input
              required
              value={form.evidence}
              onChange={(event) =>
                setForm({ ...form, evidence: event.target.value })
              }
              placeholder="Contoh: Berita acara dan kuitansi tersedia"
            />
          </label>
          <button className="button button-primary button-block">
            Catat Penyaluran
          </button>
        </form>
      )}
    </Modal>
  );
}

function UsersView({
  users,
  currentUser,
  onRefresh,
}: {
  users: User[];
  currentUser: User;
  onRefresh: () => Promise<void>;
}) {
  async function changeRole(userId: string, role: Role) {
    await patch(`/admin/users/${userId}`, { role });
    await onRefresh();
  }

  return (
    <>
      <ViewHeading
        eyebrow="Role-based access control"
        title="Pengguna dan hak akses"
        description="Super Administrator dapat mengubah role. Administrator dapat meninjau daftar akun terverifikasi."
      />
      <article className="dashboard-panel data-panel">
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Pengguna</th>
                <th>Kontak</th>
                <th>Role</th>
                <th>Verifikasi</th>
                <th>Terdaftar</th>
              </tr>
            </thead>
            <tbody>
              {users.map((item) => (
                <tr key={item.id}>
                  <td>
                    <strong>{item.name}</strong>
                  </td>
                  <td>
                    {item.email}
                    <span>{item.phone}</span>
                  </td>
                  <td>
                    {currentUser.role === "super_admin" && item.id !== currentUser.id ? (
                      <select
                        value={item.role}
                        onChange={(event) =>
                          changeRole(item.id, event.target.value as Role)
                        }
                      >
                        <option value="donatur">Donatur</option>
                        <option value="pemohon">Pemohon</option>
                        <option value="konselor">Konselor</option>
                        <option value="operator">Operator</option>
                        <option value="admin">Admin</option>
                      </select>
                    ) : (
                      <span className="status-badge">{roleLabel(item.role)}</span>
                    )}
                  </td>
                  <td>
                    <span className="verified">
                      <BadgeCheck size={15} /> Terverifikasi
                    </span>
                  </td>
                  <td>{shortDate(item.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </article>
    </>
  );
}

function AuditView({ adminOverview }: { adminOverview: AdminOverview | null }) {
  return (
    <>
      <ViewHeading
        eyebrow="Jejak aktivitas"
        title="Audit log sistem"
        description="Login, transaksi, perubahan pengajuan, campaign, dan penyaluran dicatat otomatis."
      />
      <article className="dashboard-panel audit-list">
        {adminOverview?.recentAudit.length ? (
          adminOverview.recentAudit.map((item) => (
            <div key={item.id}>
              <span className="audit-icon">
                <ShieldCheck />
              </span>
              <p>
                <strong>{item.action.replaceAll("_", " ")}</strong>
                <span>{item.detail}</span>
              </p>
              <small>
                {new Date(item.createdAt).toLocaleString("id-ID")} - {item.ip}
              </small>
            </div>
          ))
        ) : (
          <div className="empty-inline">
            Audit log akan terisi setelah ada aktivitas baru.
          </div>
        )}
      </article>
    </>
  );
}

function NotificationsView({
  notifications,
  onRefresh,
}: {
  notifications: Notification[];
  onRefresh: () => Promise<void>;
}) {
  async function readAll() {
    await post("/notifications/read-all");
    await onRefresh();
  }
  return (
    <>
      <ViewHeading
        eyebrow="Pusat pembaruan"
        title="Notifikasi akun"
        description="Konfirmasi donasi, perubahan status pengajuan, dan aktivitas konseling tampil di sini."
        action={
          <button className="button button-soft" onClick={readAll}>
            <Check size={17} /> Tandai semua dibaca
          </button>
        }
      />
      <article className="dashboard-panel notification-list">
        {notifications.map((item) => (
          <div className={item.read ? "" : "unread"} key={item.id}>
            <span className="notification-icon">
              <Bell />
            </span>
            <p>
              <strong>{item.title}</strong>
              <span>{item.message}</span>
            </p>
            <small>{shortDate(item.createdAt)}</small>
          </div>
        ))}
        {!notifications.length && (
          <div className="empty-inline">Belum ada notifikasi.</div>
        )}
      </article>
    </>
  );
}

function ProfileView({ user }: { user: User }) {
  const [currentPassword, setCurrentPassword] = useState("Demo1234");
  const [newPassword, setNewPassword] = useState("");
  const [message, setMessage] = useState("");

  async function changePassword(event: FormEvent) {
    event.preventDefault();
    setMessage("");
    try {
      await patch("/auth/password", { currentPassword, newPassword });
      setMessage("Password berhasil diperbarui.");
      setCurrentPassword("");
      setNewPassword("");
    } catch (caught) {
      setMessage(caught instanceof Error ? caught.message : "Perubahan gagal.");
    }
  }

  return (
    <>
      <ViewHeading
        eyebrow="Profil dan keamanan"
        title="Kelola identitas akun"
        description="Data profil dan keamanan disesuaikan dengan role pengguna."
      />
      <div className="profile-grid">
        <article className="dashboard-panel profile-card">
          <span className="profile-avatar">{user.name.charAt(0)}</span>
          <h2>{user.name}</h2>
          <p>{roleLabel(user.role)}</p>
          <div>
            <span>Email</span>
            <strong>{user.email}</strong>
          </div>
          <div>
            <span>Telepon</span>
            <strong>{user.phone}</strong>
          </div>
          <div>
            <span>Status</span>
            <strong className="verified">
              <BadgeCheck size={15} /> Terverifikasi
            </strong>
          </div>
        </article>
        <article className="dashboard-panel security-form">
          <span className="eyebrow">Keamanan akun</span>
          <h2>Ganti password</h2>
          <form onSubmit={changePassword}>
            <label className="form-field">
              <span>Password saat ini</span>
              <input
                type="password"
                required
                value={currentPassword}
                onChange={(event) => setCurrentPassword(event.target.value)}
              />
            </label>
            <label className="form-field">
              <span>Password baru</span>
              <input
                type="password"
                required
                minLength={8}
                value={newPassword}
                onChange={(event) => setNewPassword(event.target.value)}
              />
            </label>
            {message && <div className="notice notice-info">{message}</div>}
            <button className="button button-primary">Perbarui Password</button>
          </form>
        </article>
      </div>
    </>
  );
}

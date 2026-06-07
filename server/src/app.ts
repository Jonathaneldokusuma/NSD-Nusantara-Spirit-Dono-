import { randomUUID } from "node:crypto";
import bcrypt from "bcryptjs";
import cors from "cors";
import express, {
  type ErrorRequestHandler,
  type NextFunction,
  type Request,
  type Response,
} from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import { z, ZodError } from "zod";
import {
  allowRoles,
  authenticate,
  safeUser,
  signToken,
  type AuthenticatedRequest,
} from "./auth.js";
import { JsonStore } from "./store.js";
import type {
  AidApplication,
  Campaign,
  CampaignStatus,
  Donation,
  Role,
} from "./types.js";

type EmitEvent = (event: string, payload: unknown) => void;

const roleValues = [
  "donatur",
  "pemohon",
  "konselor",
  "operator",
  "admin",
  "super_admin",
] as const;

const campaignStatuses = [
  "draft",
  "verifikasi",
  "aktif",
  "darurat",
  "selesai",
  "ditutup",
] as const;

const applicationStatuses = [
  "draf",
  "diajukan",
  "konseling",
  "direkomendasikan",
  "disetujui",
  "ditolak",
  "dipublikasikan",
] as const;

function audit(
  store: JsonStore,
  request: AuthenticatedRequest | Request,
  action: string,
  detail: string,
): void {
  store.update((database) => {
    database.auditLogs.unshift({
      id: randomUUID(),
      userId: "auth" in request ? request.auth?.sub : undefined,
      action,
      detail,
      ip: request.ip || "unknown",
      createdAt: new Date().toISOString(),
    });
    database.auditLogs = database.auditLogs.slice(0, 500);
  });
}

function getDailySeries(donations: Donation[]) {
  const days = Array.from({ length: 14 }, (_, index) => {
    const date = new Date();
    date.setDate(date.getDate() - (13 - index));
    const key = date.toISOString().slice(0, 10);
    return { date: key, amount: 0 };
  });

  const successful = donations.filter((donation) => donation.status === "sukses");
  for (const donation of successful) {
    const key = donation.createdAt.slice(0, 10);
    const item = days.find((day) => day.date === key);
    if (item) item.amount += donation.amount;
  }

  return days.map((day, index) => ({
    ...day,
    amount: day.amount || 18_000_000 + index * 3_750_000 + (index % 3) * 8_500_000,
  }));
}

export function createApp(
  store = new JsonStore(),
  emit: EmitEvent = () => undefined,
) {
  const app = express();
  app.set("trust proxy", 1);
  app.use(helmet({ crossOriginResourcePolicy: false }));
  app.use(
    cors({
      origin: process.env.CLIENT_ORIGIN || "http://localhost:5173",
      credentials: true,
    }),
  );
  app.use(express.json({ limit: "2mb" }));
  app.use(
    "/api",
    rateLimit({
      windowMs: 60_000,
      limit: 120,
      standardHeaders: "draft-8",
      legacyHeaders: false,
    }),
  );

  app.get("/api/health", (_request, response) => {
    response.json({
      status: "ok",
      service: "NSD API",
      timestamp: new Date().toISOString(),
    });
  });

  app.get("/api/public/overview", (_request, response) => {
    const database = store.read();
    const campaigns = database.campaigns.filter((campaign) =>
      ["aktif", "darurat", "selesai"].includes(campaign.status),
    );
    const totalRaised = campaigns.reduce((sum, item) => sum + item.raised, 0);
    const totalDistributed = campaigns.reduce(
      (sum, item) => sum + item.distributed,
      0,
    );

    response.json({
      stats: {
        totalRaised,
        totalDistributed,
        activeCampaigns: campaigns.filter((item) =>
          ["aktif", "darurat"].includes(item.status),
        ).length,
        donors: campaigns.reduce((sum, item) => sum + item.donorCount, 0),
        verifiedApplications: database.applications.filter((item) =>
          ["direkomendasikan", "disetujui", "dipublikasikan"].includes(item.status),
        ).length,
      },
      campaigns,
      disbursements: database.disbursements,
      news: database.news,
      dailyDonations: getDailySeries(database.donations),
    });
  });

  app.get("/api/campaigns", (request, response) => {
    const status = request.query.status?.toString();
    const category = request.query.category?.toString();
    const search = request.query.search?.toString().toLowerCase();
    let campaigns = store.read().campaigns;

    if (status) campaigns = campaigns.filter((item) => item.status === status);
    if (category) campaigns = campaigns.filter((item) => item.category === category);
    if (search) {
      campaigns = campaigns.filter((item) =>
        [item.title, item.summary, item.location, item.category]
          .join(" ")
          .toLowerCase()
          .includes(search),
      );
    }
    response.json(campaigns);
  });

  app.get("/api/campaigns/:id", (request, response) => {
    const database = store.read();
    const campaign = database.campaigns.find(
      (item) => item.id === request.params.id || item.slug === request.params.id,
    );
    if (!campaign) {
      response.status(404).json({ message: "Campaign tidak ditemukan." });
      return;
    }
    response.json({
      ...campaign,
      disbursements: database.disbursements.filter(
        (item) => item.campaignId === campaign.id,
      ),
      recentDonations: database.donations
        .filter(
          (item) => item.campaignId === campaign.id && item.status === "sukses",
        )
        .slice(0, 10)
        .map((item) => ({
          ...item,
          donorName: item.anonymous
            ? "Donatur anonim"
            : database.users.find((user) => user.id === item.userId)?.name ||
              "Donatur",
        })),
    });
  });

  const registerSchema = z.object({
    name: z.string().min(3).max(120),
    email: z.email(),
    phone: z.string().min(8).max(20),
    password: z.string().min(8),
    role: z.enum(["donatur", "pemohon"]).default("donatur"),
  });

  app.post("/api/auth/register", (request, response) => {
    const input = registerSchema.parse(request.body);
    const email = input.email.toLowerCase();
    const database = store.read();
    if (database.users.some((user) => user.email === email)) {
      response.status(409).json({ message: "Email sudah terdaftar." });
      return;
    }

    const user = {
      id: randomUUID(),
      name: input.name,
      email,
      phone: input.phone,
      role: input.role,
      passwordHash: bcrypt.hashSync(input.password, 10),
      verified: true,
      createdAt: new Date().toISOString(),
    };
    store.update((data) => data.users.push(user));
    audit(store, request, "REGISTER", `Akun ${email} dibuat sebagai ${input.role}.`);
    response.status(201).json({ token: signToken(user), user: safeUser(user) });
  });

  const loginSchema = z.object({
    email: z.email(),
    password: z.string().min(1),
  });

  app.post("/api/auth/login", (request, response) => {
    const input = loginSchema.parse(request.body);
    const user = store
      .read()
      .users.find((item) => item.email === input.email.toLowerCase());
    if (!user || !bcrypt.compareSync(input.password, user.passwordHash)) {
      audit(store, request, "LOGIN_FAILED", `Login gagal untuk ${input.email}.`);
      response.status(401).json({ message: "Email atau password tidak sesuai." });
      return;
    }
    if (!user.verified) {
      response.status(403).json({ message: "Akun belum diverifikasi." });
      return;
    }

    audit(store, request, "LOGIN_SUCCESS", `Login berhasil untuk ${user.email}.`);
    response.json({ token: signToken(user), user: safeUser(user) });
  });

  app.get(
    "/api/auth/me",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      const user = store.read().users.find((item) => item.id === request.auth?.sub);
      if (!user) {
        response.status(404).json({ message: "Pengguna tidak ditemukan." });
        return;
      }
      response.json(safeUser(user));
    },
  );

  app.patch(
    "/api/auth/password",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      const input = z
        .object({
          currentPassword: z.string().min(1),
          newPassword: z.string().min(8).max(128),
        })
        .parse(request.body);
      const user = store.read().users.find((item) => item.id === request.auth?.sub);
      if (!user || !bcrypt.compareSync(input.currentPassword, user.passwordHash)) {
        response.status(400).json({ message: "Password saat ini tidak sesuai." });
        return;
      }
      store.update((database) => {
        const current = database.users.find((item) => item.id === user.id)!;
        current.passwordHash = bcrypt.hashSync(input.newPassword, 10);
      });
      audit(store, request, "PASSWORD_CHANGED", `Password ${user.email} diperbarui.`);
      response.status(204).send();
    },
  );

  app.get(
    "/api/counselors",
    authenticate,
    (_request, response) => {
      const counselors = store
        .read()
        .users.filter((user) => user.role === "konselor")
        .map(safeUser);
      response.json(counselors);
    },
  );

  const donationSchema = z.object({
    campaignId: z.string().min(1),
    amount: z.number().int().min(10_000).max(1_000_000_000),
    method: z.enum(["qris", "va_bca", "va_bni", "va_mandiri"]),
    anonymous: z.boolean().default(false),
    message: z.string().max(300).default(""),
  });

  app.post(
    "/api/donations",
    authenticate,
    allowRoles("donatur", "pemohon", "admin", "super_admin"),
    (request: AuthenticatedRequest, response) => {
      const input = donationSchema.parse(request.body);
      const campaign = store
        .read()
        .campaigns.find((item) => item.id === input.campaignId);
      if (!campaign || !["aktif", "darurat"].includes(campaign.status)) {
        response.status(400).json({ message: "Campaign tidak dapat menerima donasi." });
        return;
      }

      const timestamp = Date.now();
      const shortId = randomUUID().slice(0, 6).toUpperCase();
      const donation: Donation = {
        id: randomUUID(),
        orderId: `NSD-${timestamp}-${shortId}`,
        userId: request.auth!.sub,
        campaignId: input.campaignId,
        amount: input.amount,
        method: input.method,
        status: "pending",
        anonymous: input.anonymous,
        message: input.message,
        paymentCode:
          input.method === "qris"
            ? `QRIS-NSD-${shortId}`
            : `8808${String(timestamp).slice(-10)}`,
        createdAt: new Date().toISOString(),
      };
      store.update((database) => database.donations.unshift(donation));
      audit(
        store,
        request,
        "DONATION_CREATED",
        `${donation.orderId} senilai Rp${donation.amount}.`,
      );
      response.status(201).json(donation);
    },
  );

  app.post(
    "/api/donations/:id/confirm",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      const database = store.read();
      const donation = database.donations.find(
        (item) => item.id === request.params.id,
      );
      if (!donation) {
        response.status(404).json({ message: "Donasi tidak ditemukan." });
        return;
      }
      if (
        donation.userId !== request.auth?.sub &&
        !["admin", "super_admin"].includes(request.auth!.role)
      ) {
        response.status(403).json({ message: "Donasi bukan milik akun ini." });
        return;
      }

      if (donation.status !== "sukses") {
        store.update((data) => {
          const current = data.donations.find((item) => item.id === donation.id)!;
          current.status = "sukses";
          current.paidAt = new Date().toISOString();
          const campaign = data.campaigns.find(
            (item) => item.id === current.campaignId,
          );
          if (campaign) {
            campaign.raised += current.amount;
            campaign.donorCount += 1;
            campaign.updatedAt = new Date().toISOString();
          }
          data.notifications.unshift({
            id: randomUUID(),
            userId: current.userId,
            title: "Donasi berhasil",
            message: `Donasi Rp${current.amount.toLocaleString("id-ID")} telah dikonfirmasi.`,
            channel: "in_app",
            read: false,
            createdAt: new Date().toISOString(),
          });
        });
        emit("campaign.updated", { campaignId: donation.campaignId });
      }
      audit(store, request, "DONATION_CONFIRMED", donation.orderId);
      response.json(
        store.read().donations.find((item) => item.id === donation.id),
      );
    },
  );

  app.get(
    "/api/donations/mine",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      const database = store.read();
      response.json(
        database.donations
          .filter((item) => item.userId === request.auth?.sub)
          .map((item) => ({
            ...item,
            campaign: database.campaigns.find(
              (campaign) => campaign.id === item.campaignId,
            ),
          })),
      );
    },
  );

  const applicationSchema = z.object({
    title: z.string().min(8).max(180),
    category: z.string().min(3).max(80),
    location: z.string().min(3).max(180),
    amountNeeded: z.number().int().min(100_000),
    story: z.string().min(50).max(5000),
    documents: z.array(z.string().min(2)).min(1),
  });

  app.post(
    "/api/applications",
    authenticate,
    allowRoles("pemohon", "donatur"),
    (request: AuthenticatedRequest, response) => {
      const input = applicationSchema.parse(request.body);
      const now = new Date().toISOString();
      const application: AidApplication = {
        id: randomUUID(),
        applicantId: request.auth!.sub,
        ...input,
        status: "diajukan",
        createdAt: now,
        updatedAt: now,
      };
      store.update((database) => database.applications.unshift(application));
      audit(store, request, "APPLICATION_CREATED", application.title);
      emit("application.updated", { applicationId: application.id });
      response.status(201).json(application);
    },
  );

  app.get(
    "/api/applications/mine",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      response.json(
        store
          .read()
          .applications.filter((item) => item.applicantId === request.auth?.sub),
      );
    },
  );

  app.get(
    "/api/applications",
    authenticate,
    allowRoles("konselor", "operator", "admin", "super_admin"),
    (_request, response) => {
      const database = store.read();
      response.json(
        database.applications.map((item) => ({
          ...item,
          applicant: safeUser(
            database.users.find((user) => user.id === item.applicantId)!,
          ),
          counselor: item.counselorId
            ? safeUser(
                database.users.find((user) => user.id === item.counselorId)!,
              )
            : undefined,
        })),
      );
    },
  );

  const applicationUpdateSchema = z.object({
    status: z.enum(applicationStatuses).optional(),
    counselorId: z.string().optional(),
    counselorNotes: z.string().max(2000).optional(),
    adminNotes: z.string().max(2000).optional(),
  });

  app.patch(
    "/api/applications/:id",
    authenticate,
    allowRoles("konselor", "operator", "admin", "super_admin"),
    (request: AuthenticatedRequest, response) => {
      const input = applicationUpdateSchema.parse(request.body);
      const application = store
        .read()
        .applications.find((item) => item.id === request.params.id);
      if (!application) {
        response.status(404).json({ message: "Pengajuan tidak ditemukan." });
        return;
      }

      store.update((database) => {
        const current = database.applications.find(
          (item) => item.id === application.id,
        )!;
        Object.assign(current, input, { updatedAt: new Date().toISOString() });

        if (
          input.counselorId &&
          !database.sessions.some(
            (session) => session.applicationId === current.id,
          )
        ) {
          database.sessions.unshift({
            id: randomUUID(),
            userId: current.applicantId,
            counselorId: input.counselorId,
            applicationId: current.id,
            topic: `Verifikasi: ${current.title}`,
            status: "aktif",
            messages: [
              {
                id: randomUUID(),
                senderId: input.counselorId,
                text: "Halo, saya telah ditugaskan untuk mendampingi verifikasi pengajuan Anda.",
                createdAt: new Date().toISOString(),
              },
            ],
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          });
          current.status = "konseling";
        }

        if (input.status === "disetujui" && !current.campaignId) {
          const campaignId = randomUUID();
          const campaign: Campaign = {
            id: campaignId,
            slug: current.title
              .toLowerCase()
              .replace(/[^a-z0-9]+/g, "-")
              .replace(/(^-|-$)/g, ""),
            title: current.title,
            summary: current.story.slice(0, 150),
            description: current.story,
            category: current.category,
            location: current.location,
            status: "verifikasi",
            target: current.amountNeeded,
            raised: 0,
            distributed: 0,
            donorCount: 0,
            daysLeft: 30,
            accent: "#3D8A73",
            icon: "hand-heart",
            verified: true,
            createdBy: request.auth!.sub,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          };
          database.campaigns.unshift(campaign);
          current.campaignId = campaignId;
        }
      });
      audit(
        store,
        request,
        "APPLICATION_UPDATED",
        `${application.id}: ${input.status || "data diperbarui"}`,
      );
      emit("application.updated", { applicationId: application.id });
      response.json(
        store.read().applications.find((item) => item.id === application.id),
      );
    },
  );

  app.get(
    "/api/sessions",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      const database = store.read();
      const sessions = database.sessions.filter((session) =>
        request.auth?.role === "konselor"
          ? session.counselorId === request.auth.sub
          : session.userId === request.auth?.sub,
      );
      response.json(
        sessions.map((session) => ({
          ...session,
          user: safeUser(
            database.users.find((user) => user.id === session.userId)!,
          ),
          counselor: safeUser(
            database.users.find((user) => user.id === session.counselorId)!,
          ),
        })),
      );
    },
  );

  const sessionSchema = z.object({
    counselorId: z.string().min(1),
    topic: z.string().min(5).max(180),
  });

  app.post(
    "/api/sessions",
    authenticate,
    allowRoles("donatur", "pemohon"),
    (request: AuthenticatedRequest, response) => {
      const input = sessionSchema.parse(request.body);
      const counselor = store
        .read()
        .users.find(
          (user) => user.id === input.counselorId && user.role === "konselor",
        );
      if (!counselor) {
        response.status(404).json({ message: "Konselor tidak ditemukan." });
        return;
      }
      const now = new Date().toISOString();
      const session = {
        id: randomUUID(),
        userId: request.auth!.sub,
        counselorId: counselor.id,
        topic: input.topic,
        status: "menunggu" as const,
        messages: [],
        createdAt: now,
        updatedAt: now,
      };
      store.update((database) => database.sessions.unshift(session));
      audit(store, request, "SESSION_CREATED", input.topic);
      emit("session.updated", { sessionId: session.id });
      response.status(201).json(session);
    },
  );

  const messageSchema = z.object({ text: z.string().min(1).max(1500) });

  app.post(
    "/api/sessions/:id/messages",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      const input = messageSchema.parse(request.body);
      const session = store
        .read()
        .sessions.find((item) => item.id === request.params.id);
      if (!session) {
        response.status(404).json({ message: "Sesi tidak ditemukan." });
        return;
      }
      if (
        ![session.userId, session.counselorId].includes(request.auth!.sub) &&
        !["admin", "super_admin"].includes(request.auth!.role)
      ) {
        response.status(403).json({ message: "Anda bukan peserta sesi ini." });
        return;
      }

      const message = {
        id: randomUUID(),
        senderId: request.auth!.sub,
        text: input.text,
        createdAt: new Date().toISOString(),
      };
      store.update((database) => {
        const current = database.sessions.find((item) => item.id === session.id)!;
        current.messages.push(message);
        current.status = "aktif";
        current.updatedAt = message.createdAt;
      });
      audit(store, request, "CHAT_MESSAGE", `Pesan pada sesi ${session.id}.`);
      emit("chat.message", { sessionId: session.id, message });
      response.status(201).json(message);
    },
  );

  app.get(
    "/api/notifications",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      response.json(
        store
          .read()
          .notifications.filter((item) => item.userId === request.auth?.sub),
      );
    },
  );

  app.post(
    "/api/notifications/read-all",
    authenticate,
    (request: AuthenticatedRequest, response) => {
      store.update((database) => {
        for (const notification of database.notifications) {
          if (notification.userId === request.auth?.sub) notification.read = true;
        }
      });
      response.status(204).send();
    },
  );

  app.get(
    "/api/admin/overview",
    authenticate,
    allowRoles("operator", "admin", "super_admin", "konselor"),
    (_request, response) => {
      const database = store.read();
      response.json({
        totals: {
          users: database.users.length,
          campaigns: database.campaigns.length,
          donations: database.donations.length,
          successfulAmount: database.donations
            .filter((item) => item.status === "sukses")
            .reduce((sum, item) => sum + item.amount, 0),
          pendingApplications: database.applications.filter((item) =>
            ["diajukan", "konseling", "direkomendasikan"].includes(item.status),
          ).length,
          activeSessions: database.sessions.filter(
            (item) => item.status !== "selesai",
          ).length,
        },
        recentAudit: database.auditLogs.slice(0, 20),
      });
    },
  );

  app.get(
    "/api/admin/users",
    authenticate,
    allowRoles("admin", "super_admin"),
    (_request, response) => {
      response.json(store.read().users.map(safeUser));
    },
  );

  app.patch(
    "/api/admin/users/:id",
    authenticate,
    allowRoles("super_admin"),
    (request, response) => {
      const input = z
        .object({
          role: z.enum(roleValues).optional(),
          verified: z.boolean().optional(),
        })
        .parse(request.body);
      const user = store.read().users.find((item) => item.id === request.params.id);
      if (!user) {
        response.status(404).json({ message: "Pengguna tidak ditemukan." });
        return;
      }
      store.update((database) => {
        Object.assign(
          database.users.find((item) => item.id === user.id)!,
          input,
        );
      });
      response.json(safeUser(user));
    },
  );

  const campaignSchema = z.object({
    title: z.string().min(5).max(200),
    summary: z.string().min(10).max(300),
    description: z.string().min(20).max(5000),
    category: z.string().min(2).max(80),
    location: z.string().min(2).max(160),
    target: z.number().int().min(100_000),
    status: z.enum(campaignStatuses).default("draft"),
    daysLeft: z.number().int().min(0).max(365).default(30),
  });

  app.post(
    "/api/admin/campaigns",
    authenticate,
    allowRoles("admin", "super_admin"),
    (request: AuthenticatedRequest, response) => {
      const input = campaignSchema.parse(request.body);
      const now = new Date().toISOString();
      const campaign: Campaign = {
        id: randomUUID(),
        slug: `${input.title
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "-")
          .replace(/(^-|-$)/g, "")}-${Date.now().toString().slice(-4)}`,
        ...input,
        raised: 0,
        distributed: 0,
        donorCount: 0,
        accent: "#3D8A73",
        icon: "hand-heart",
        verified: true,
        createdBy: request.auth!.sub,
        createdAt: now,
        updatedAt: now,
      };
      store.update((database) => database.campaigns.unshift(campaign));
      audit(store, request, "CAMPAIGN_CREATED", campaign.title);
      emit("campaign.updated", { campaignId: campaign.id });
      response.status(201).json(campaign);
    },
  );

  app.patch(
    "/api/admin/campaigns/:id",
    authenticate,
    allowRoles("operator", "admin", "super_admin"),
    (request: AuthenticatedRequest, response) => {
      const input = campaignSchema.partial().parse(request.body);
      const campaign = store
        .read()
        .campaigns.find((item) => item.id === request.params.id);
      if (!campaign) {
        response.status(404).json({ message: "Campaign tidak ditemukan." });
        return;
      }
      store.update((database) => {
        Object.assign(
          database.campaigns.find((item) => item.id === campaign.id)!,
          input,
          { updatedAt: new Date().toISOString() },
        );
      });
      audit(store, request, "CAMPAIGN_UPDATED", campaign.title);
      emit("campaign.updated", { campaignId: campaign.id });
      response.json(
        store.read().campaigns.find((item) => item.id === campaign.id),
      );
    },
  );

  const disbursementSchema = z.object({
    campaignId: z.string().min(1),
    recipient: z.string().min(3).max(180),
    description: z.string().min(5).max(500),
    amount: z.number().int().min(1),
    evidence: z.string().min(3).max(300),
  });

  app.post(
    "/api/admin/disbursements",
    authenticate,
    allowRoles("operator", "admin", "super_admin"),
    (request: AuthenticatedRequest, response) => {
      const input = disbursementSchema.parse(request.body);
      const campaign = store
        .read()
        .campaigns.find((item) => item.id === input.campaignId);
      if (!campaign) {
        response.status(404).json({ message: "Campaign tidak ditemukan." });
        return;
      }
      if (campaign.distributed + input.amount > campaign.raised) {
        response
          .status(400)
          .json({ message: "Nominal penyaluran melebihi dana tersedia." });
        return;
      }
      const disbursement = {
        id: randomUUID(),
        ...input,
        date: new Date().toISOString().slice(0, 10),
        verifiedBy: request.auth!.sub,
      };
      store.update((database) => {
        database.disbursements.unshift(disbursement);
        const current = database.campaigns.find(
          (item) => item.id === input.campaignId,
        )!;
        current.distributed += input.amount;
        current.updatedAt = new Date().toISOString();
      });
      audit(
        store,
        request,
        "DISBURSEMENT_CREATED",
        `${campaign.title}: Rp${input.amount}.`,
      );
      emit("campaign.updated", { campaignId: campaign.id });
      response.status(201).json(disbursement);
    },
  );

  const errorHandler: ErrorRequestHandler = (
    error,
    _request,
    response,
    _next,
  ) => {
    if (error instanceof ZodError) {
      response.status(400).json({
        message: "Data yang dikirim belum valid.",
        errors: error.issues.map((issue) => ({
          field: issue.path.join("."),
          message: issue.message,
        })),
      });
      return;
    }
    console.error(error);
    response.status(500).json({ message: "Terjadi kesalahan pada server." });
  };
  app.use(errorHandler);

  return app;
}

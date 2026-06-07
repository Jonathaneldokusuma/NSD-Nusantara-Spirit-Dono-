import bcrypt from "bcryptjs";
import type { Database, Role, User } from "./types.js";

const now = new Date("2026-06-07T08:00:00.000Z").toISOString();

function demoUser(
  id: string,
  name: string,
  email: string,
  role: Role,
  extra: Partial<User> = {},
): User {
  return {
    id,
    name,
    email,
    phone: "081234567890",
    role,
    passwordHash: bcrypt.hashSync("Demo1234", 10),
    verified: true,
    createdAt: now,
    ...extra,
  };
}

export function createSeedDatabase(): Database {
  const users: User[] = [
    demoUser("usr-donor", "Dina Prameswari", "donatur@nsd.id", "donatur"),
    demoUser("usr-applicant", "Raka Saputra", "pemohon@nsd.id", "pemohon"),
    demoUser("usr-counselor", "Maria Agnes", "konselor@nsd.id", "konselor", {
      faith: "Lintas Iman",
      specialization: "Pendampingan krisis dan keluarga",
      available: true,
    }),
    demoUser("usr-operator", "Fikri Ramadhan", "operator@nsd.id", "operator"),
    demoUser("usr-admin", "Alya Kusuma", "admin@nsd.id", "admin"),
    demoUser("usr-super", "Jonathan Eldo", "superadmin@nsd.id", "super_admin"),
  ];

  return {
    users,
    campaigns: [
      {
        id: "cmp-banjir",
        slug: "bantuan-banjir-bandang-sumatera",
        title: "Bantuan Banjir Bandang Sumatera",
        summary:
          "Makanan, air bersih, dan layanan kesehatan untuk keluarga terdampak.",
        description:
          "Ratusan keluarga membutuhkan bantuan darurat setelah banjir bandang merusak rumah dan akses jalan. Dana digunakan untuk paket pangan, air bersih, obat-obatan, serta hunian sementara.",
        category: "Bencana Alam",
        location: "Sumatera Barat",
        status: "darurat",
        target: 750_000_000,
        raised: 512_450_000,
        distributed: 286_000_000,
        donorCount: 4231,
        daysLeft: 9,
        accent: "#E85D4A",
        icon: "waves",
        verified: true,
        createdBy: "usr-admin",
        createdAt: "2026-05-19T07:00:00.000Z",
        updatedAt: now,
      },
      {
        id: "cmp-gempa",
        slug: "pemulihan-gempa-nusa-tenggara",
        title: "Pemulihan Gempa Nusa Tenggara",
        summary:
          "Dukung pembangunan hunian sementara dan ruang belajar anak.",
        description:
          "Program pemulihan pascagempa berfokus pada hunian sementara, sanitasi, dan ruang belajar aman bagi anak-anak di wilayah terdampak.",
        category: "Pemulihan",
        location: "Nusa Tenggara Timur",
        status: "aktif",
        target: 500_000_000,
        raised: 321_800_000,
        distributed: 195_000_000,
        donorCount: 2874,
        daysLeft: 21,
        accent: "#E9A23B",
        icon: "house",
        verified: true,
        createdBy: "usr-admin",
        createdAt: "2026-05-11T07:00:00.000Z",
        updatedAt: now,
      },
      {
        id: "cmp-medis",
        slug: "layanan-medis-darurat-anak",
        title: "Layanan Medis Darurat Anak",
        summary:
          "Biaya tindakan medis dan transportasi bagi anak dari keluarga rentan.",
        description:
          "Campaign terverifikasi untuk membantu tindakan medis darurat, transportasi rujukan, dan kebutuhan pemulihan anak dari keluarga rentan.",
        category: "Kesehatan",
        location: "Jawa Timur",
        status: "aktif",
        target: 300_000_000,
        raised: 188_900_000,
        distributed: 103_500_000,
        donorCount: 1962,
        daysLeft: 17,
        accent: "#3D8A73",
        icon: "heart-pulse",
        verified: true,
        createdBy: "usr-admin",
        createdAt: "2026-05-29T07:00:00.000Z",
        updatedAt: now,
      },
      {
        id: "cmp-longsor",
        slug: "dapur-umum-korban-longsor",
        title: "Dapur Umum Korban Longsor",
        summary:
          "Penuhi kebutuhan makanan hangat dan perlengkapan bayi selama masa tanggap.",
        description:
          "Dapur umum beroperasi untuk menyediakan makanan hangat, susu, perlengkapan bayi, dan kebutuhan dasar bagi warga yang mengungsi.",
        category: "Bencana Alam",
        location: "Jawa Barat",
        status: "aktif",
        target: 180_000_000,
        raised: 74_350_000,
        distributed: 31_000_000,
        donorCount: 821,
        daysLeft: 12,
        accent: "#5876A7",
        icon: "utensils",
        verified: true,
        createdBy: "usr-admin",
        createdAt: "2026-06-02T07:00:00.000Z",
        updatedAt: now,
      },
    ],
    donations: [
      {
        id: "don-1",
        orderId: "NSD-20260601-A1B2C3",
        userId: "usr-donor",
        campaignId: "cmp-banjir",
        amount: 250_000,
        method: "qris",
        status: "sukses",
        anonymous: false,
        message: "Semoga keadaan segera pulih.",
        paymentCode: "QRIS-NSD-A1B2C3",
        createdAt: "2026-06-01T09:20:00.000Z",
        paidAt: "2026-06-01T09:21:00.000Z",
      },
      {
        id: "don-2",
        orderId: "NSD-20260527-D4E5F6",
        userId: "usr-donor",
        campaignId: "cmp-medis",
        amount: 100_000,
        method: "va_bca",
        status: "sukses",
        anonymous: true,
        message: "",
        paymentCode: "88081234567890",
        createdAt: "2026-05-27T13:10:00.000Z",
        paidAt: "2026-05-27T13:14:00.000Z",
      },
    ],
    applications: [
      {
        id: "app-1",
        applicantId: "usr-applicant",
        title: "Bantuan pemulihan rumah pascabanjir",
        category: "Bencana Alam",
        location: "Padang Pariaman, Sumatera Barat",
        amountNeeded: 85_000_000,
        story:
          "Rumah keluarga rusak berat dan perlengkapan usaha hanyut. Kami membutuhkan bantuan bahan bangunan dan modal pemulihan.",
        documents: ["KTP terverifikasi", "Foto kondisi rumah", "Surat keterangan RT"],
        status: "konseling",
        counselorId: "usr-counselor",
        counselorNotes:
          "Identitas dan kondisi awal telah dikonfirmasi. Menunggu verifikasi dokumen lapangan.",
        createdAt: "2026-06-03T08:00:00.000Z",
        updatedAt: now,
      },
    ],
    sessions: [
      {
        id: "ses-1",
        userId: "usr-applicant",
        counselorId: "usr-counselor",
        applicationId: "app-1",
        topic: "Verifikasi kondisi dan pendampingan",
        status: "aktif",
        messages: [
          {
            id: "msg-1",
            senderId: "usr-counselor",
            text: "Selamat sore, saya Maria yang akan mendampingi proses verifikasi pengajuan Anda.",
            createdAt: "2026-06-06T08:00:00.000Z",
          },
          {
            id: "msg-2",
            senderId: "usr-applicant",
            text: "Terima kasih. Dokumen dan foto kondisi rumah sudah saya siapkan.",
            createdAt: "2026-06-06T08:03:00.000Z",
          },
        ],
        createdAt: "2026-06-06T08:00:00.000Z",
        updatedAt: now,
      },
    ],
    disbursements: [
      {
        id: "dis-1",
        campaignId: "cmp-banjir",
        date: "2026-06-05",
        recipient: "Posko Sungai Limau",
        description: "1.200 paket pangan dan air bersih",
        amount: 146_000_000,
        evidence: "Dokumentasi penyaluran terverifikasi",
        verifiedBy: "usr-admin",
      },
      {
        id: "dis-2",
        campaignId: "cmp-banjir",
        date: "2026-05-29",
        recipient: "Puskesmas Darurat",
        description: "Obat, hygiene kit, dan perlengkapan medis",
        amount: 140_000_000,
        evidence: "Berita acara dan kuitansi tersedia",
        verifiedBy: "usr-admin",
      },
      {
        id: "dis-3",
        campaignId: "cmp-gempa",
        date: "2026-06-01",
        recipient: "Desa Oebelo",
        description: "Material 35 unit hunian sementara",
        amount: 195_000_000,
        evidence: "Foto progres dan faktur material",
        verifiedBy: "usr-admin",
      },
      {
        id: "dis-4",
        campaignId: "cmp-medis",
        date: "2026-06-04",
        recipient: "RS Mitra Keluarga",
        description: "Tindakan medis dan transportasi rujukan",
        amount: 103_500_000,
        evidence: "Invoice rumah sakit terverifikasi",
        verifiedBy: "usr-admin",
      },
    ],
    notifications: [
      {
        id: "not-1",
        userId: "usr-donor",
        title: "Donasi berhasil",
        message:
          "Donasi Rp250.000 untuk Bantuan Banjir Bandang Sumatera telah dikonfirmasi.",
        channel: "in_app",
        read: false,
        createdAt: "2026-06-01T09:21:00.000Z",
      },
      {
        id: "not-2",
        userId: "usr-applicant",
        title: "Konselor telah ditugaskan",
        message: "Maria Agnes akan mendampingi proses verifikasi pengajuan Anda.",
        channel: "in_app",
        read: true,
        createdAt: "2026-06-06T08:00:00.000Z",
      },
    ],
    news: [
      {
        id: "news-1",
        title: "Akses air bersih menjadi kebutuhan utama di Sumatera Barat",
        excerpt:
          "Tim lapangan memprioritaskan distribusi air minum dan hygiene kit ke tiga kecamatan.",
        location: "Sumatera Barat",
        severity: "darurat",
        publishedAt: "2026-06-07T06:30:00.000Z",
      },
      {
        id: "news-2",
        title: "Ruang belajar sementara mulai digunakan",
        excerpt:
          "Anak-anak di dua desa terdampak gempa kembali mengikuti kegiatan belajar.",
        location: "Nusa Tenggara Timur",
        severity: "pemulihan",
        publishedAt: "2026-06-06T04:15:00.000Z",
      },
    ],
    auditLogs: [],
  };
}


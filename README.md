# NSD - Nusantara Spiritual Donation

Platform donasi darurat yang menghubungkan donatur, pemohon bantuan, konselor,
operator, dan administrator dalam satu alur yang terverifikasi dan transparan.

Implementasi ini dibuat berdasarkan dokumen konsep, SKPL, DPPL, dan WBS NSD.
Versi saat ini adalah MVP full-stack responsif/PWA yang dapat dijalankan langsung
untuk demonstrasi, pengujian alur, dan pengembangan lanjutan.

## Fitur yang Sudah Berjalan

- Beranda responsif dengan campaign darurat dan statistik dampak.
- Daftar dan detail campaign dengan progres dana real-time.
- Alur donasi 3 langkah dengan simulasi QRIS dan Virtual Account.
- Konfirmasi pembayaran simulasi yang memperbarui saldo campaign.
- Dashboard transparansi publik, grafik donasi, dan riwayat penyaluran.
- Registrasi dan login dengan JWT serta role-based access control.
- Pengajuan bantuan beserta dokumen pendukung.
- Penugasan konselor, rekomendasi, persetujuan admin, dan draft campaign otomatis.
- Chat konseling real-time menggunakan Socket.IO.
- Panel admin untuk campaign, penyaluran dana, user, dan audit log.
- Notifikasi dalam aplikasi dan riwayat donasi pengguna.
- Ganti password dari dashboard profil.
- Hot Module Replacement Vite dan restart otomatis API saat development.

## Stack

- Frontend: React 19, TypeScript, Vite, React Router, Lucide.
- Backend: Node.js, Express, TypeScript, JWT, Zod, Socket.IO.
- Penyimpanan demo: JSON lokal persisten di `server/data/nsd.json`.
- Target production: PostgreSQL, object storage, Midtrans, FCM, WhatsApp, dan email.

Skema PostgreSQL acuan tersedia di
[`docs/postgresql-schema.sql`](docs/postgresql-schema.sql).

## Menjalankan Aplikasi

Persyaratan: Node.js 20 atau lebih baru.

```bash
npm install
npm run dev
```

Buka:

- Web dengan live refresh: `http://localhost:5173`
- API: `http://localhost:4000/api`
- Health check: `http://localhost:4000/api/health`

Vite akan memperbarui frontend tanpa reload penuh. Backend menggunakan `tsx watch`
dan akan restart otomatis saat file server berubah.

## Akun Demo

Semua akun menggunakan password `Demo1234`.

| Peran | Email |
| --- | --- |
| Donatur | `donatur@nsd.id` |
| Pemohon | `pemohon@nsd.id` |
| Konselor | `konselor@nsd.id` |
| Operator | `operator@nsd.id` |
| Admin | `admin@nsd.id` |
| Super Admin | `superadmin@nsd.id` |

## Build Production

```bash
npm run build
npm start
```

Setelah build, Express menyajikan frontend dan API dari
`http://localhost:4000`.

## Perintah Penting

```bash
npm run typecheck
npm test
npm run build
npm run reset:data
```

`reset:data` mengembalikan database demo ke kondisi awal.

## Struktur Repository

```text
client/                  React web app responsif
server/                  REST API, auth, data, Socket.IO
docs/                    Skema dan dokumentasi teknis
.github/workflows/       Continuous integration
```

## API Utama

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/public/overview`
- `GET /api/campaigns`
- `POST /api/donations`
- `POST /api/donations/:id/confirm`
- `POST /api/applications`
- `PATCH /api/applications/:id`
- `GET /api/sessions`
- `POST /api/sessions/:id/messages`
- `POST /api/admin/campaigns`
- `POST /api/admin/disbursements`

Rincian kontrak tersedia di [`docs/API.md`](docs/API.md).

## Konfigurasi

Salin `.env.example` menjadi `.env` untuk mengganti port, JWT secret, lokasi
data, atau menyiapkan kredensial integrasi production.

Integrasi Midtrans, AWS, FCM, Twilio, dan SES sengaja tidak memakai kredensial
nyata di repository. Mode demo menyediakan simulasi lokal agar seluruh alur
bisnis tetap dapat diuji tanpa layanan eksternal.

## Docker

```bash
docker build -t nsd-app .
docker run --rm -p 4000:4000 -e JWT_SECRET=ubah-secret-ini nsd-app
```

## Verifikasi

Project diverifikasi dengan:

- Unit/integration test API dan helper frontend.
- TypeScript type-check untuk client dan server.
- Production build Vite dan TypeScript.
- Uji visual desktop dan mobile.
- Uji UI end-to-end login, donasi, pembayaran simulasi, dan pembaruan campaign.

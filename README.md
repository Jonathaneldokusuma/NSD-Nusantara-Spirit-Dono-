# NSD - Nusantara Spiritual Donation

Aplikasi Flutter lintas Android, iOS, dan Web untuk donasi darurat, pengajuan
bantuan, konseling, verifikasi, serta transparansi penyaluran dana.

Implementasi dibuat berdasarkan dokumen konsep, SKPL, DPPL, dan WBS NSD.

## Fitur

- Beranda Flutter responsif dengan campaign darurat dan statistik dampak.
- Daftar, pencarian, filter, dan detail campaign terverifikasi.
- Donasi tiga tahap dengan simulasi QRIS dan Virtual Account.
- Pembaruan dana campaign real-time melalui Socket.IO.
- Registrasi, login JWT, pemulihan sesi, dan akses berbasis peran.
- Pengajuan bantuan beserta daftar dokumen pendukung.
- Penugasan konselor, rekomendasi, persetujuan, dan pembuatan campaign.
- Chat konseling real-time.
- Dashboard donatur, pemohon, konselor, operator, admin, dan super admin.
- Panel campaign, pengguna, notifikasi, profil, dan audit aktivitas.
- Dashboard transparansi beserta grafik dan riwayat penyaluran.
- Flutter hot reload untuk pengembangan Web dan mobile.

## Stack

- Client: Flutter 3 / Dart, Material 3, Firebase Auth, Cloud Firestore, HTTP, Shared Preferences, Socket.IO.
- Platform: Android, iOS, dan Web/PWA.
- API: Node.js, Express, TypeScript, JWT, Firebase Admin, Zod, Socket.IO.
- Penyimpanan demo: JSON lokal persisten di `server/data/nsd.json`.
- Acuan production: Firebase Auth, Cloud Firestore, Storage, FCM, Midtrans, WhatsApp, email.

Skema PostgreSQL tersedia di
[`docs/postgresql-schema.sql`](docs/postgresql-schema.sql).

## Menjalankan dengan Hot Reload

Persyaratan:

- Flutter 3.43 atau versi stable terbaru.
- Node.js 20 atau lebih baru.
- Google Chrome untuk target Flutter Web.

```bash
npm install
cd client
flutter pub get
cd ..
npm run dev
```

Perintah tersebut menjalankan:

- Flutter Web dengan hot reload: `http://localhost:5173`
- REST API dan Socket.IO: `http://localhost:4000`
- Health check: `http://localhost:4000/api/health`

Untuk menjalankan langsung di Android:

```bash
npm run dev:api
cd client
flutter run
```

Android emulator otomatis memakai `http://10.0.2.2:4000/api`. Untuk perangkat
fisik, gunakan alamat IP komputer:

```bash
flutter run --dart-define=API_URL=http://192.168.1.10:4000/api
```

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

## Verifikasi dan Build

```bash
npm run typecheck
npm test
npm run build
```

Build Flutter Web dihasilkan pada `client/build/web`. Setelah build, Express
menyajikan aplikasi Flutter dan API pada `http://localhost:4000`.

Build Android:

```bash
cd client
flutter build apk
```

Perintah lain:

```bash
npm run reset:data
npm run dev:api
npm run dev:flutter
```

## Struktur Repository

```text
client/                  Flutter app Android, iOS, dan Web
  lib/core/              Model, API client, sesi, dan tema
  lib/screens/           Halaman publik, donasi, dan dashboard multi-role
  lib/widgets/           Komponen UI reusable
server/                  REST API, JWT, Socket.IO, dan data demo
docs/                    Kontrak API dan skema PostgreSQL
.github/workflows/       CI Node.js dan Flutter
```

## Konfigurasi Production

Gunakan `--dart-define=API_URL=https://api.domain-anda.id/api` ketika membangun
client untuk production. Untuk mode Firebase Hosting, build web lalu deploy
folder `client/build/web` dengan Firebase Hosting:

```bash
npm run build
firebase deploy --only hosting
```

Untuk mode Firebase, tambahkan:

```bash
--dart-define=FIREBASE_API_KEY=...
--dart-define=FIREBASE_APP_ID=...
--dart-define=FIREBASE_MESSAGING_SENDER_ID=...
--dart-define=FIREBASE_PROJECT_ID=nsd-donasi
```

Di backend Railway, set `FIREBASE_SERVICE_ACCOUNT_JSON` agar token Firebase
di-verifikasi oleh API. Tanpa override, build Flutter Web memakai endpoint
relatif `/api` pada domain yang sama.

## Deploy Split

Rekomendasi deployment sekarang:

- Flutter Web dan admin panel: Firebase Hosting
- API dan Socket.IO: Railway

Alur deploy:

1. Build web client dengan `npm run build`
2. Deploy hosting dengan `firebase deploy --only hosting`
3. Deploy service backend di Railway
4. Set `API_URL` ke domain Railway saat build Flutter

Integrasi pembayaran saat ini menggunakan simulasi lokal agar alur dapat diuji
tanpa kredensial. Midtrans, AWS, FCM, Twilio, dan SES perlu kredensial production
sebelum aplikasi menerima transaksi nyata.

## Docker

```bash
docker build -t nsd-app .
docker run --rm -p 4000:4000 -e JWT_SECRET=ubah-secret-ini nsd-app
```

Image Docker membangun Flutter Web dan API, lalu menyajikannya melalui satu
service Node.js pada port 4000.

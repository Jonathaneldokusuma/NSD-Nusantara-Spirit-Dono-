# Kontrak API MVP NSD

Semua request dan response menggunakan JSON. Endpoint privat memerlukan header:

```http
Authorization: Bearer <jwt>
```

## Autentikasi

### `POST /api/auth/register`

```json
{
  "name": "Nama Pengguna",
  "email": "nama@email.com",
  "phone": "08123456789",
  "password": "minimal8karakter",
  "role": "donatur"
}
```

Role registrasi publik: `donatur` atau `pemohon`.

### `POST /api/auth/login`

```json
{
  "email": "donatur@nsd.id",
  "password": "Demo1234"
}
```

### `PATCH /api/auth/password`

```json
{
  "currentPassword": "password-lama",
  "newPassword": "password-baru"
}
```

## Campaign dan Transparansi

- `GET /api/public/overview`
- `GET /api/campaigns?status=aktif&category=Bencana%20Alam`
- `GET /api/campaigns/:idOrSlug`

## Donasi

### `POST /api/donations`

```json
{
  "campaignId": "cmp-banjir",
  "amount": 100000,
  "method": "qris",
  "anonymous": false,
  "message": "Semoga segera pulih."
}
```

Metode: `qris`, `va_bca`, `va_bni`, atau `va_mandiri`.

### `POST /api/donations/:id/confirm`

Endpoint demo untuk mensimulasikan webhook payment gateway yang valid.

### `GET /api/donations/mine`

Mengambil riwayat donasi akun aktif.

## Pengajuan Bantuan

### `POST /api/applications`

```json
{
  "title": "Bantuan pemulihan rumah",
  "category": "Bencana Alam",
  "location": "Kabupaten, Provinsi",
  "amountNeeded": 85000000,
  "story": "Penjelasan kebutuhan minimal 50 karakter.",
  "documents": ["KTP", "Foto kondisi", "Surat keterangan"]
}
```

- `GET /api/applications/mine`
- `GET /api/applications`
- `PATCH /api/applications/:id`

Status: `diajukan`, `konseling`, `direkomendasikan`, `disetujui`, `ditolak`,
dan `dipublikasikan`.

## Konseling

- `GET /api/counselors`
- `GET /api/sessions`
- `POST /api/sessions`
- `POST /api/sessions/:id/messages`

Event Socket.IO:

- `campaign.updated`
- `application.updated`
- `session.updated`
- `chat.message`

## Administrasi

- `GET /api/admin/overview`
- `GET /api/admin/users`
- `PATCH /api/admin/users/:id`
- `POST /api/admin/campaigns`
- `PATCH /api/admin/campaigns/:id`
- `POST /api/admin/disbursements`


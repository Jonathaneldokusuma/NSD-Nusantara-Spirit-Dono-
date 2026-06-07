CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE user_role AS ENUM (
  'donatur',
  'pemohon',
  'konselor',
  'operator',
  'admin',
  'super_admin'
);

CREATE TYPE campaign_status AS ENUM (
  'draft',
  'verifikasi',
  'aktif',
  'darurat',
  'selesai',
  'ditutup'
);

CREATE TYPE donation_status AS ENUM (
  'pending',
  'sukses',
  'gagal',
  'expired',
  'refund'
);

CREATE TYPE application_status AS ENUM (
  'draf',
  'diajukan',
  'konseling',
  'direkomendasikan',
  'disetujui',
  'ditolak',
  'dipublikasikan'
);

CREATE TABLE users (
  user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nama_lengkap VARCHAR(200) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE,
  role user_role NOT NULL DEFAULT 'donatur',
  password_hash VARCHAR(255) NOT NULL,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  faith VARCHAR(80),
  specialization VARCHAR(255),
  available BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE aid_applications (
  application_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  applicant_id UUID NOT NULL REFERENCES users(user_id),
  counselor_id UUID REFERENCES users(user_id),
  title VARCHAR(300) NOT NULL,
  category VARCHAR(80) NOT NULL,
  location VARCHAR(255) NOT NULL,
  amount_needed BIGINT NOT NULL CHECK (amount_needed >= 100000),
  story TEXT NOT NULL,
  documents JSONB NOT NULL DEFAULT '[]'::jsonb,
  status application_status NOT NULL DEFAULT 'diajukan',
  counselor_notes TEXT,
  admin_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE campaigns (
  campaign_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  application_id UUID REFERENCES aid_applications(application_id),
  slug VARCHAR(320) UNIQUE NOT NULL,
  judul VARCHAR(300) NOT NULL,
  ringkasan VARCHAR(500) NOT NULL,
  deskripsi TEXT NOT NULL,
  category VARCHAR(80) NOT NULL,
  location VARCHAR(255) NOT NULL,
  target_dana BIGINT NOT NULL CHECK (target_dana > 0),
  terkumpul BIGINT NOT NULL DEFAULT 0,
  tersalurkan BIGINT NOT NULL DEFAULT 0,
  donor_count INTEGER NOT NULL DEFAULT 0,
  status campaign_status NOT NULL DEFAULT 'draft',
  tanggal_mulai DATE NOT NULL DEFAULT CURRENT_DATE,
  tanggal_selesai DATE,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_by UUID NOT NULL REFERENCES users(user_id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE donations (
  donation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id VARCHAR(100) UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES users(user_id),
  campaign_id UUID NOT NULL REFERENCES campaigns(campaign_id),
  nominal BIGINT NOT NULL CHECK (nominal >= 10000),
  metode_bayar VARCHAR(30) NOT NULL,
  status donation_status NOT NULL DEFAULT 'pending',
  pesan_donatur TEXT,
  is_anonim BOOLEAN NOT NULL DEFAULT FALSE,
  payment_code VARCHAR(150),
  waktu_donasi TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  waktu_bayar TIMESTAMPTZ
);

CREATE TABLE transactions (
  transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  donation_id UUID NOT NULL REFERENCES donations(donation_id),
  gateway VARCHAR(50) NOT NULL,
  ref_number VARCHAR(100) UNIQUE NOT NULL,
  status_gateway VARCHAR(30) NOT NULL,
  waktu_bayar TIMESTAMPTZ,
  fee_gateway INTEGER NOT NULL DEFAULT 0,
  response_raw JSONB,
  signature_hash VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE counseling_sessions (
  session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(user_id),
  counselor_id UUID NOT NULL REFERENCES users(user_id),
  application_id UUID REFERENCES aid_applications(application_id),
  topic VARCHAR(300) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'menunggu',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE counseling_messages (
  message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES counseling_sessions(session_id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(user_id),
  message_text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE disbursements (
  disbursement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID NOT NULL REFERENCES campaigns(campaign_id),
  recipient VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  amount BIGINT NOT NULL CHECK (amount > 0),
  evidence_url TEXT,
  verified_by UUID NOT NULL REFERENCES users(user_id),
  disbursed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notifications (
  notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(user_id),
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  channel VARCHAR(20) NOT NULL,
  delivery_status VARCHAR(20) NOT NULL DEFAULT 'terkirim',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_logs (
  audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(user_id),
  action VARCHAR(100) NOT NULL,
  detail TEXT NOT NULL,
  ip_address INET,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_campaign_status ON campaigns(status);
CREATE INDEX idx_donation_user ON donations(user_id, waktu_donasi DESC);
CREATE INDEX idx_donation_campaign ON donations(campaign_id, status);
CREATE INDEX idx_application_status ON aid_applications(status, updated_at DESC);
CREATE INDEX idx_session_participants ON counseling_sessions(user_id, counselor_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);


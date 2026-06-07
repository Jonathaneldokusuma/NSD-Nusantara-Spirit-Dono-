import {
  ArrowRight,
  BadgeCheck,
  Eye,
  EyeOff,
  HandHeart,
  HeartHandshake,
  ShieldCheck,
} from "lucide-react";
import { useMemo, useState, type FormEvent } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import type { Role } from "../types";

const demoAccounts = [
  { label: "Donatur", email: "donatur@nsd.id" },
  { label: "Pemohon", email: "pemohon@nsd.id" },
  { label: "Konselor", email: "konselor@nsd.id" },
  { label: "Admin", email: "admin@nsd.id" },
];

export function AuthPage({ mode }: { mode: "login" | "register" }) {
  const { login, register } = useAuth();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const defaultRole = params.get("role") === "pemohon" ? "pemohon" : "donatur";
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("Demo1234");
  const [role, setRole] =
    useState<Extract<Role, "donatur" | "pemohon">>(defaultRole);
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const next = useMemo(() => params.get("next") || "/app", [params]);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");
    try {
      if (mode === "login") {
        await login(email, password);
      } else {
        await register({ name, email, phone, password, role });
      }
      navigate(next);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Proses gagal.");
    } finally {
      setLoading(false);
    }
  }

  function useDemo(emailValue: string) {
    setEmail(emailValue);
    setPassword("Demo1234");
  }

  return (
    <section className="auth-page">
      <div className="auth-art">
        <div className="auth-art-inner">
          <Link className="auth-brand" to="/">
            <span>
              <HandHeart />
            </span>
            NSD
          </Link>
          <div>
            <span className="hero-kicker">
              <BadgeCheck size={16} /> Platform bantuan terverifikasi
            </span>
            <h1>
              Kepedulian yang
              <br />
              sampai pada tujuan.
            </h1>
            <p>
              Satu ruang untuk membantu, mengajukan kebutuhan, mendampingi, dan
              mengawal transparansi.
            </p>
          </div>
          <div className="auth-art-points">
            <span>
              <ShieldCheck /> Akses berbasis peran
            </span>
            <span>
              <HeartHandshake /> Verifikasi konselor dan admin
            </span>
          </div>
        </div>
      </div>
      <div className="auth-form-side">
        <div className="auth-form-card">
          <Link className="back-link" to="/">
            Kembali ke beranda
          </Link>
          <span className="eyebrow">
            {mode === "login" ? "Selamat datang kembali" : "Bergabung dengan NSD"}
          </span>
          <h2>
            {mode === "login" ? "Masuk ke akun Anda" : "Buat akun baru"}
          </h2>
          <p>
            {mode === "login"
              ? "Akses dashboard sesuai peran dan lanjutkan aktivitas Anda."
              : "Pilih tujuan akun agar pengalaman Anda lebih relevan."}
          </p>

          {mode === "register" && (
            <div className="role-choice">
              <button
                className={role === "donatur" ? "active" : ""}
                onClick={() => setRole("donatur")}
              >
                <HandHeart />
                <span>
                  <strong>Saya ingin berdonasi</strong>
                  Jelajahi dan bantu campaign.
                </span>
              </button>
              <button
                className={role === "pemohon" ? "active" : ""}
                onClick={() => setRole("pemohon")}
              >
                <HeartHandshake />
                <span>
                  <strong>Saya membutuhkan bantuan</strong>
                  Ajukan dan pantau verifikasi.
                </span>
              </button>
            </div>
          )}

          {mode === "login" && (
            <div className="demo-accounts">
              <span>Akses cepat akun demo</span>
              <div>
                {demoAccounts.map((account) => (
                  <button
                    onClick={() => useDemo(account.email)}
                    key={account.email}
                  >
                    {account.label}
                  </button>
                ))}
              </div>
            </div>
          )}

          <form onSubmit={submit} className="auth-form">
            {mode === "register" && (
              <>
                <label className="form-field">
                  <span>Nama lengkap</span>
                  <input
                    required
                    minLength={3}
                    value={name}
                    onChange={(event) => setName(event.target.value)}
                    placeholder="Nama Anda"
                  />
                </label>
                <label className="form-field">
                  <span>Nomor telepon</span>
                  <input
                    required
                    minLength={8}
                    value={phone}
                    onChange={(event) => setPhone(event.target.value)}
                    placeholder="08xxxxxxxxxx"
                  />
                </label>
              </>
            )}
            <label className="form-field">
              <span>Email</span>
              <input
                type="email"
                required
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="nama@email.com"
              />
            </label>
            <label className="form-field">
              <span>Password</span>
              <div className="password-input">
                <input
                  type={showPassword ? "text" : "password"}
                  required
                  minLength={8}
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  placeholder="Minimal 8 karakter"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((value) => !value)}
                  aria-label="Tampilkan password"
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </label>
            {error && <div className="notice notice-error">{error}</div>}
            <button
              className="button button-primary button-large button-block"
              disabled={loading}
            >
              {loading
                ? "Memproses..."
                : mode === "login"
                  ? "Masuk ke Dashboard"
                  : "Buat Akun"}
              {!loading && <ArrowRight size={18} />}
            </button>
          </form>
          <p className="auth-switch">
            {mode === "login" ? "Belum punya akun?" : "Sudah punya akun?"}{" "}
            <Link to={mode === "login" ? "/register" : "/login"}>
              {mode === "login" ? "Daftar sekarang" : "Masuk di sini"}
            </Link>
          </p>
          {mode === "login" && (
            <small className="demo-hint">
              Semua akun demo memakai password <b>Demo1234</b>.
            </small>
          )}
        </div>
      </div>
    </section>
  );
}


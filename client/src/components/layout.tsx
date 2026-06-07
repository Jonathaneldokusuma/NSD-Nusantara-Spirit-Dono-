import {
  Bell,
  ChevronDown,
  LayoutDashboard,
  LogIn,
  Menu,
  ShieldCheck,
  X,
} from "lucide-react";
import { useState, type ReactNode } from "react";
import { Link, NavLink, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { roleLabel } from "../lib/format";
import { Logo } from "./ui";

export function PublicLayout() {
  const { user, logout } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);
  const location = useLocation();

  const closeMenu = () => setMenuOpen(false);

  return (
    <div className="site-shell">
      <header className="site-header">
        <div className="container header-inner">
          <Logo />
          <nav className={`main-nav ${menuOpen ? "is-open" : ""}`}>
            <NavLink to="/" onClick={closeMenu}>
              Beranda
            </NavLink>
            <NavLink to="/campaign" onClick={closeMenu}>
              Campaign
            </NavLink>
            <NavLink to="/transparansi" onClick={closeMenu}>
              Transparansi
            </NavLink>
            <a href="/#cara-kerja" onClick={closeMenu}>
              Cara Kerja
            </a>
            <a href="/#tentang" onClick={closeMenu}>
              Tentang
            </a>
          </nav>
          <div className="header-actions">
            {user ? (
              <>
                <Link className="icon-button" to="/app" aria-label="Notifikasi">
                  <Bell size={19} />
                </Link>
                <Link className="user-chip" to="/app">
                  <span>{user.name.charAt(0)}</span>
                  <div>
                    <strong>{user.name.split(" ")[0]}</strong>
                    <small>{roleLabel(user.role)}</small>
                  </div>
                  <ChevronDown size={15} />
                </Link>
                <button className="link-button desktop-only" onClick={logout}>
                  Keluar
                </button>
              </>
            ) : (
              <>
                <Link className="button button-ghost desktop-only" to="/login">
                  <LogIn size={17} /> Masuk
                </Link>
                <Link
                  className="button button-primary desktop-only"
                  to="/register"
                >
                  Mulai Membantu
                </Link>
              </>
            )}
            <button
              className="mobile-menu-button"
              onClick={() => setMenuOpen((value) => !value)}
              aria-label="Buka menu"
            >
              {menuOpen ? <X /> : <Menu />}
            </button>
          </div>
        </div>
        {menuOpen && (
          <div className="mobile-account-actions">
            {user ? (
              <>
                <Link to="/app" onClick={closeMenu}>
                  <LayoutDashboard size={18} /> Buka Dashboard
                </Link>
                <button
                  onClick={() => {
                    logout();
                    closeMenu();
                  }}
                >
                  Keluar
                </button>
              </>
            ) : (
              <>
                <Link to={`/login?next=${encodeURIComponent(location.pathname)}`}>
                  Masuk
                </Link>
                <Link to="/register">Daftar</Link>
              </>
            )}
          </div>
        )}
      </header>
      <main>
        <Outlet />
      </main>
      <Footer />
    </div>
  );
}

function Footer() {
  return (
    <footer className="site-footer" id="tentang">
      <div className="container footer-grid">
        <div className="footer-about">
          <Logo />
          <p>
            Platform gotong royong digital untuk bantuan darurat yang cepat,
            terverifikasi, dan transparan.
          </p>
          <span className="security-note">
            <ShieldCheck size={17} /> Data dan transaksi tercatat dalam audit log.
          </span>
        </div>
        <div>
          <strong>Jelajahi</strong>
          <Link to="/campaign">Campaign Aktif</Link>
          <Link to="/transparansi">Transparansi Dana</Link>
          <Link to="/register">Ajukan Bantuan</Link>
        </div>
        <div>
          <strong>Dukungan</strong>
          <a href="mailto:halo@nsd.id">halo@nsd.id</a>
          <a href="#cara-kerja">Cara Kerja</a>
          <span>Surabaya, Indonesia</span>
        </div>
      </div>
      <div className="container footer-bottom">
        <span>NSD 2026. Bersama membantu, bersama menguatkan.</span>
        <span>Mode MVP akademik dengan integrasi pembayaran simulasi.</span>
      </div>
    </footer>
  );
}

export function PageHero({
  eyebrow,
  title,
  description,
  children,
}: {
  eyebrow: string;
  title: string;
  description: string;
  children?: ReactNode;
}) {
  return (
    <section className="page-hero">
      <div className="container">
        <span className="eyebrow">{eyebrow}</span>
        <h1>{title}</h1>
        <p>{description}</p>
        {children}
      </div>
    </section>
  );
}


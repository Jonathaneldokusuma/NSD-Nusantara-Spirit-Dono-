import {
  ArrowRight,
  BadgeCheck,
  BarChart3,
  CheckCircle2,
  HeartHandshake,
  MessageCircleHeart,
  ShieldCheck,
  Sparkles,
  UsersRound,
  WalletCards,
} from "lucide-react";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { io } from "socket.io-client";
import { CampaignCard, SectionHeading, Spinner } from "../components/ui";
import { api } from "../lib/api";
import { rupiah, shortDate } from "../lib/format";
import type { PublicOverview } from "../types";

export function HomePage() {
  const [overview, setOverview] = useState<PublicOverview | null>(null);
  const [error, setError] = useState("");

  async function load() {
    try {
      setOverview(await api<PublicOverview>("/public/overview"));
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Gagal memuat data.");
    }
  }

  useEffect(() => {
    void load();
    const socket = io({ path: "/socket.io" });
    socket.on("campaign.updated", load);
    return () => {
      socket.disconnect();
    };
  }, []);

  if (!overview && !error) return <Spinner />;

  const urgent = overview?.campaigns.find((item) => item.status === "darurat");

  return (
    <>
      <section className="hero-section">
        <div className="hero-pattern" />
        <div className="container hero-grid">
          <div className="hero-copy">
            <span className="hero-kicker">
              <Sparkles size={16} /> Gerakan bantuan terverifikasi
            </span>
            <h1>
              Bantuan cepat.
              <br />
              Dampak yang <em>terlihat.</em>
            </h1>
            <p>
              Hubungkan kepedulian dengan kebutuhan nyata melalui campaign
              terverifikasi, penyaluran transparan, dan pendampingan manusiawi.
            </p>
            <div className="hero-actions">
              <Link className="button button-primary button-large" to="/campaign">
                Lihat Campaign <ArrowRight size={18} />
              </Link>
              <Link
                className="button button-light button-large"
                to="/register?role=pemohon"
              >
                Ajukan Bantuan
              </Link>
            </div>
            <div className="hero-trust">
              <span>
                <BadgeCheck size={17} /> Verifikasi berlapis
              </span>
              <span>
                <ShieldCheck size={17} /> Transparansi real-time
              </span>
            </div>
          </div>
          {urgent && (
            <div className="urgent-feature">
              <div
                className="urgent-visual"
                style={{ "--campaign-accent": urgent.accent } as React.CSSProperties}
              >
                <span className="pulse-ring" />
                <HeartHandshake size={72} strokeWidth={1.2} />
                <span className="urgent-pill">BUTUH BANTUAN SEGERA</span>
              </div>
              <div className="urgent-body">
                <span>{urgent.location}</span>
                <h2>{urgent.title}</h2>
                <p>{urgent.summary}</p>
                <div className="urgent-progress">
                  <div>
                    <strong>{rupiah(urgent.raised, true)}</strong>
                    <span>dari {rupiah(urgent.target, true)}</span>
                  </div>
                  <b>{Math.round((urgent.raised / urgent.target) * 100)}%</b>
                </div>
                <div className="progress progress-large">
                  <span
                    style={{
                      width: `${Math.min(100, (urgent.raised / urgent.target) * 100)}%`,
                      background: urgent.accent,
                    }}
                  />
                </div>
                <Link
                  className="button button-dark button-block"
                  to={`/campaign/${urgent.slug}`}
                >
                  Bantu Sekarang <ArrowRight size={18} />
                </Link>
              </div>
            </div>
          )}
        </div>
      </section>

      {overview && (
        <section className="impact-strip">
          <div className="container impact-grid">
            <div>
              <WalletCards />
              <span>
                <strong>{rupiah(overview.stats.totalRaised, true)}</strong>
                Dana terkumpul
              </span>
            </div>
            <div>
              <UsersRound />
              <span>
                <strong>{overview.stats.donors.toLocaleString("id-ID")}</strong>
                Donatur bergerak
              </span>
            </div>
            <div>
              <BarChart3 />
              <span>
                <strong>{overview.stats.activeCampaigns}</strong>
                Campaign aktif
              </span>
            </div>
            <div>
              <CheckCircle2 />
              <span>
                <strong>{rupiah(overview.stats.totalDistributed, true)}</strong>
                Sudah disalurkan
              </span>
            </div>
          </div>
        </section>
      )}

      <section className="section">
        <div className="container">
          <SectionHeading
            eyebrow="Campaign terverifikasi"
            title="Kepedulian Anda dibutuhkan hari ini"
            description="Setiap campaign melewati pemeriksaan dokumen, komunikasi konselor, dan persetujuan pengelola."
            action={
              <Link className="text-link" to="/campaign">
                Lihat semua <ArrowRight size={17} />
              </Link>
            }
          />
          {error ? (
            <div className="notice notice-error">{error}</div>
          ) : (
            <div className="campaign-grid">
              {overview?.campaigns.slice(0, 3).map((campaign) => (
                <CampaignCard campaign={campaign} key={campaign.id} />
              ))}
            </div>
          )}
        </div>
      </section>

      <section className="section section-soft" id="cara-kerja">
        <div className="container">
          <SectionHeading
            eyebrow="Proses yang dapat dipercaya"
            title="Bantuan tidak berhenti di tombol donasi"
            description="NSD mengawal kebutuhan sejak diajukan sampai dana tersalurkan dan bukti dapat dilihat publik."
          />
          <div className="steps-grid">
            <article>
              <span className="step-number">01</span>
              <div className="step-icon">
                <HeartHandshake />
              </div>
              <h3>Pengajuan kebutuhan</h3>
              <p>Pemohon mengirim cerita, lokasi, target, dan bukti pendukung.</p>
            </article>
            <article>
              <span className="step-number">02</span>
              <div className="step-icon">
                <MessageCircleHeart />
              </div>
              <h3>Verifikasi manusiawi</h3>
              <p>Konselor berkomunikasi langsung dan memberi rekomendasi.</p>
            </article>
            <article>
              <span className="step-number">03</span>
              <div className="step-icon">
                <ShieldCheck />
              </div>
              <h3>Publikasi dan donasi</h3>
              <p>Admin menyetujui campaign dan donatur dapat membantu dalam 3 langkah.</p>
            </article>
            <article>
              <span className="step-number">04</span>
              <div className="step-icon">
                <BarChart3 />
              </div>
              <h3>Penyaluran transparan</h3>
              <p>Nominal, penerima, kegunaan, dan bukti penyaluran selalu diperbarui.</p>
            </article>
          </div>
        </div>
      </section>

      {overview && (
        <section className="section transparency-preview">
          <div className="container transparency-grid">
            <div>
              <span className="eyebrow">Transparansi publik</span>
              <h2>Setiap rupiah punya jejak yang jelas.</h2>
              <p>
                Pantau dana masuk, dana tersalur, saldo tersedia, dan bukti
                penggunaan tanpa harus login.
              </p>
              <ul className="check-list">
                <li>
                  <CheckCircle2 /> Pembaruan data campaign real-time
                </li>
                <li>
                  <CheckCircle2 /> Riwayat penyaluran dapat diperiksa
                </li>
                <li>
                  <CheckCircle2 /> Aktivitas kritis tercatat dalam audit log
                </li>
              </ul>
              <Link className="button button-primary" to="/transparansi">
                Buka Dashboard Transparansi <ArrowRight size={17} />
              </Link>
            </div>
            <div className="transparency-card">
              <div className="transparency-card-head">
                <div>
                  <span>Total dana terkelola</span>
                  <strong>{rupiah(overview.stats.totalRaised)}</strong>
                </div>
                <span className="live-badge">
                  <i /> Live
                </span>
              </div>
              <div className="bar-comparison">
                <div>
                  <span>
                    Dana tersalur
                    <b>{rupiah(overview.stats.totalDistributed, true)}</b>
                  </span>
                  <div>
                    <i
                      style={{
                        width: `${Math.round(
                          (overview.stats.totalDistributed /
                            overview.stats.totalRaised) *
                            100,
                        )}%`,
                      }}
                    />
                  </div>
                </div>
                <div>
                  <span>
                    Saldo tersedia
                    <b>
                      {rupiah(
                        overview.stats.totalRaised -
                          overview.stats.totalDistributed,
                        true,
                      )}
                    </b>
                  </span>
                  <div>
                    <i
                      className="bar-gold"
                      style={{
                        width: `${Math.round(
                          ((overview.stats.totalRaised -
                            overview.stats.totalDistributed) /
                            overview.stats.totalRaised) *
                            100,
                        )}%`,
                      }}
                    />
                  </div>
                </div>
              </div>
              <div className="latest-disbursement">
                <span>Penyaluran terbaru</span>
                {overview.disbursements.slice(0, 2).map((item) => (
                  <div key={item.id}>
                    <i />
                    <p>
                      <strong>{item.description}</strong>
                      <span>
                        {shortDate(item.date)} - {item.recipient}
                      </span>
                    </p>
                    <b>{rupiah(item.amount, true)}</b>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>
      )}

      <section className="section section-dark">
        <div className="container cta-band">
          <div>
            <span className="eyebrow eyebrow-light">Mari bergerak bersama</span>
            <h2>Satu tindakan kecil dapat menjadi awal pemulihan.</h2>
          </div>
          <div>
            <Link className="button button-light button-large" to="/campaign">
              Donasi Sekarang
            </Link>
            <Link
              className="button button-outline-light button-large"
              to="/register?role=pemohon"
            >
              Ajukan Bantuan
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}

import {
  ArrowLeft,
  BadgeCheck,
  Banknote,
  CalendarDays,
  Check,
  CheckCircle2,
  Clock3,
  Copy,
  HandHeart,
  HeartHandshake,
  MapPin,
  MessageCircle,
  QrCode,
  ShieldCheck,
  UserRound,
} from "lucide-react";
import { useEffect, useMemo, useState, type FormEvent } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { api, post } from "../lib/api";
import { rupiah, shortDate } from "../lib/format";
import type { Campaign, Donation } from "../types";
import { Modal, ProgressBar, Spinner, StatusBadge } from "../components/ui";

const nominalOptions = [25_000, 50_000, 100_000, 250_000, 500_000];

export function CampaignPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [campaign, setCampaign] = useState<Campaign | null>(null);
  const [donateOpen, setDonateOpen] = useState(false);
  const [step, setStep] = useState(1);
  const [amount, setAmount] = useState(100_000);
  const [method, setMethod] = useState<Donation["method"]>("qris");
  const [anonymous, setAnonymous] = useState(false);
  const [message, setMessage] = useState("");
  const [donation, setDonation] = useState<Donation | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  async function load() {
    setCampaign(await api<Campaign>(`/campaigns/${id}`));
  }

  useEffect(() => {
    void load();
  }, [id]);

  const progress = useMemo(
    () =>
      campaign
        ? Math.min(100, Math.round((campaign.raised / campaign.target) * 100))
        : 0,
    [campaign],
  );

  function openDonation() {
    if (!user) {
      navigate(`/login?next=${encodeURIComponent(`/campaign/${id}`)}`);
      return;
    }
    setDonateOpen(true);
    setStep(1);
    setDonation(null);
    setError("");
  }

  async function createDonation(event: FormEvent) {
    event.preventDefault();
    if (!campaign) return;
    setSubmitting(true);
    setError("");
    try {
      const created = await post<Donation>("/donations", {
        campaignId: campaign.id,
        amount,
        method,
        anonymous,
        message,
      });
      setDonation(created);
      setStep(2);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Donasi gagal dibuat.");
    } finally {
      setSubmitting(false);
    }
  }

  async function confirmPayment() {
    if (!donation) return;
    setSubmitting(true);
    try {
      const confirmed = await post<Donation>(
        `/donations/${donation.id}/confirm`,
      );
      setDonation(confirmed);
      setStep(3);
      await load();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Konfirmasi gagal.");
    } finally {
      setSubmitting(false);
    }
  }

  if (!campaign) return <Spinner />;

  return (
    <>
      <section className="campaign-detail-hero">
        <div className="container">
          <Link className="back-link" to="/campaign">
            <ArrowLeft size={17} /> Kembali ke campaign
          </Link>
          <div className="campaign-detail-grid">
            <div
              className="campaign-detail-visual"
              style={{ "--campaign-accent": campaign.accent } as React.CSSProperties}
            >
              <span className="visual-orb orb-one" />
              <span className="visual-orb orb-two" />
              <HeartHandshake size={108} strokeWidth={1.1} />
              <StatusBadge status={campaign.status} />
              <span className="detail-location">
                <MapPin size={16} /> {campaign.location}
              </span>
            </div>
            <div className="campaign-detail-copy">
              <span className="eyebrow">{campaign.category}</span>
              <h1>{campaign.title}</h1>
              <p>{campaign.summary}</p>
              <span className="verified verified-large">
                <BadgeCheck size={18} /> Identitas dan kebutuhan telah diverifikasi
              </span>
              <div className="funding-box">
                <div className="funding-head">
                  <span>
                    <strong>{rupiah(campaign.raised)}</strong>
                    terkumpul dari target {rupiah(campaign.target)}
                  </span>
                  <b>{progress}%</b>
                </div>
                <ProgressBar
                  value={campaign.raised}
                  target={campaign.target}
                  color={campaign.accent}
                />
                <div className="funding-meta">
                  <span>
                    <UserRound size={16} />
                    <b>{campaign.donorCount.toLocaleString("id-ID")}</b> donatur
                  </span>
                  <span>
                    <CalendarDays size={16} />
                    <b>{campaign.daysLeft}</b> hari lagi
                  </span>
                  <span>
                    <Banknote size={16} />
                    <b>{rupiah(campaign.distributed, true)}</b> tersalur
                  </span>
                </div>
                <button
                  className="button button-primary button-large button-block"
                  onClick={openDonation}
                >
                  <HandHeart size={19} /> Donasi Sekarang
                </button>
                <small className="secure-copy">
                  <ShieldCheck size={15} /> Pembayaran demo aman dan tercatat di
                  audit log.
                </small>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container detail-content-grid">
          <article className="story-content">
            <span className="eyebrow">Tentang kebutuhan ini</span>
            <h2>Pulihkan keadaan bersama</h2>
            <p>{campaign.description}</p>
            <div className="verification-note">
              <BadgeCheck />
              <div>
                <strong>Hasil verifikasi NSD</strong>
                <p>
                  Dokumen identitas, kondisi lapangan, dan tujuan penggunaan dana
                  telah ditinjau oleh konselor serta administrator.
                </p>
              </div>
            </div>
            <h3>Rencana penggunaan dana</h3>
            <ul className="usage-list">
              <li>
                <CheckCircle2 />
                <span>
                  <strong>Kebutuhan darurat</strong>
                  Pangan, air bersih, kesehatan, dan perlindungan sementara.
                </span>
              </li>
              <li>
                <CheckCircle2 />
                <span>
                  <strong>Pemulihan keluarga</strong>
                  Dukungan hunian, pendidikan, dan mata pencaharian.
                </span>
              </li>
              <li>
                <CheckCircle2 />
                <span>
                  <strong>Dokumentasi terbuka</strong>
                  Setiap penyaluran akan muncul di dashboard transparansi.
                </span>
              </li>
            </ul>
          </article>
          <aside className="detail-aside">
            <article className="panel">
              <span className="eyebrow">Penyaluran terbaru</span>
              <h3>Dana yang sudah digunakan</h3>
              {campaign.disbursements?.length ? (
                <div className="mini-timeline">
                  {campaign.disbursements.map((item) => (
                    <div key={item.id}>
                      <i />
                      <p>
                        <small>{shortDate(item.date)}</small>
                        <strong>{item.description}</strong>
                        <span>{item.recipient}</span>
                      </p>
                      <b>{rupiah(item.amount, true)}</b>
                    </div>
                  ))}
                </div>
              ) : (
                <p>Belum ada penyaluran untuk campaign ini.</p>
              )}
              <Link className="text-link" to="/transparansi">
                Lihat laporan lengkap
              </Link>
            </article>
            <article className="panel counselor-callout">
              <MessageCircle />
              <h3>Butuh pendampingan?</h3>
              <p>
                Konselor NSD tersedia untuk komunikasi verifikasi dan dukungan
                emosional lintas iman.
              </p>
              <Link className="button button-soft button-block" to="/app">
                Hubungi Konselor
              </Link>
            </article>
          </aside>
        </div>
      </section>

      <Modal
        open={donateOpen}
        onClose={() => setDonateOpen(false)}
        size="medium"
      >
        <div className="donation-modal">
          <div className="modal-heading">
            <span className="eyebrow">Donasi dalam 3 langkah</span>
            <h2>
              {step === 1 && "Tentukan bantuan Anda"}
              {step === 2 && "Selesaikan pembayaran"}
              {step === 3 && "Terima kasih sudah bergerak"}
            </h2>
            <p>{campaign.title}</p>
          </div>
          <div className="stepper">
            {[1, 2, 3].map((item) => (
              <span className={step >= item ? "active" : ""} key={item}>
                {step > item ? <Check size={14} /> : item}
              </span>
            ))}
          </div>

          {step === 1 && (
            <form onSubmit={createDonation}>
              <label className="field-label">Pilih nominal donasi</label>
              <div className="amount-grid">
                {nominalOptions.map((option) => (
                  <button
                    type="button"
                    className={amount === option ? "active" : ""}
                    onClick={() => setAmount(option)}
                    key={option}
                  >
                    {rupiah(option)}
                  </button>
                ))}
              </div>
              <label className="form-field">
                <span>Nominal lainnya</span>
                <div className="input-prefix">
                  <b>Rp</b>
                  <input
                    type="number"
                    min={10000}
                    value={amount}
                    onChange={(event) => setAmount(Number(event.target.value))}
                  />
                </div>
              </label>
              <label className="field-label">Metode pembayaran</label>
              <div className="payment-options">
                <button
                  type="button"
                  className={method === "qris" ? "active" : ""}
                  onClick={() => setMethod("qris")}
                >
                  <QrCode /> <span>QRIS<small>Semua e-wallet</small></span>
                </button>
                <button
                  type="button"
                  className={method === "va_bca" ? "active" : ""}
                  onClick={() => setMethod("va_bca")}
                >
                  <Banknote /> <span>Virtual Account<small>Simulasi BCA</small></span>
                </button>
              </div>
              <label className="form-field">
                <span>Pesan atau doa (opsional)</span>
                <textarea
                  value={message}
                  maxLength={300}
                  onChange={(event) => setMessage(event.target.value)}
                  placeholder="Tuliskan dukungan Anda..."
                />
              </label>
              <label className="check-field">
                <input
                  type="checkbox"
                  checked={anonymous}
                  onChange={(event) => setAnonymous(event.target.checked)}
                />
                Tampilkan donasi sebagai anonim
              </label>
              {error && <div className="notice notice-error">{error}</div>}
              <button
                className="button button-primary button-large button-block"
                disabled={submitting || amount < 10_000}
              >
                {submitting ? "Menyiapkan..." : `Lanjut bayar ${rupiah(amount)}`}
              </button>
            </form>
          )}

          {step === 2 && donation && (
            <div className="payment-stage">
              {method === "qris" ? (
                <div className="qr-placeholder" aria-label="QRIS simulasi">
                  <QrCode size={140} strokeWidth={1.2} />
                  <span>{donation.paymentCode}</span>
                </div>
              ) : (
                <div className="va-number">
                  <span>Nomor Virtual Account</span>
                  <strong>{donation.paymentCode}</strong>
                  <button
                    onClick={() =>
                      navigator.clipboard?.writeText(donation.paymentCode)
                    }
                  >
                    <Copy size={16} /> Salin nomor
                  </button>
                </div>
              )}
              <div className="payment-summary">
                <span>
                  Total pembayaran <strong>{rupiah(donation.amount)}</strong>
                </span>
                <span>
                  Order ID <strong>{donation.orderId}</strong>
                </span>
                <span className="countdown">
                  <Clock3 size={16} /> Berlaku 15:00 menit
                </span>
              </div>
              <div className="notice notice-info">
                Ini adalah mode demo. Tombol berikut mensimulasikan webhook
                payment gateway yang valid.
              </div>
              {error && <div className="notice notice-error">{error}</div>}
              <button
                className="button button-primary button-large button-block"
                onClick={confirmPayment}
                disabled={submitting}
              >
                {submitting ? "Memverifikasi..." : "Simulasikan Pembayaran Berhasil"}
              </button>
            </div>
          )}

          {step === 3 && donation && (
            <div className="success-stage">
              <span className="success-icon">
                <Check size={34} />
              </span>
              <h3>Donasi Anda sudah dikonfirmasi.</h3>
              <p>
                Bantuan sebesar <strong>{rupiah(donation.amount)}</strong> telah
                tercatat dan progress campaign langsung diperbarui.
              </p>
              <div className="receipt">
                <span>
                  Order ID <b>{donation.orderId}</b>
                </span>
                <span>
                  Status <b className="text-success">Berhasil</b>
                </span>
              </div>
              <button
                className="button button-primary button-block"
                onClick={() => {
                  setDonateOpen(false);
                  navigate("/app");
                }}
              >
                Lihat Riwayat Donasi
              </button>
            </div>
          )}
        </div>
      </Modal>
    </>
  );
}


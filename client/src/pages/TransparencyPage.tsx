import {
  ArrowDownToLine,
  BadgeCheck,
  Banknote,
  CircleDollarSign,
  Clock3,
  Users,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { PageHero } from "../components/layout";
import { ProgressBar, Spinner, StatusBadge } from "../components/ui";
import { api } from "../lib/api";
import { rupiah, shortDate } from "../lib/format";
import type { PublicOverview } from "../types";

export function TransparencyPage() {
  const [overview, setOverview] = useState<PublicOverview | null>(null);

  useEffect(() => {
    api<PublicOverview>("/public/overview").then(setOverview);
  }, []);

  const chartPoints = useMemo(() => {
    if (!overview) return "";
    const values = overview.dailyDonations.map((item) => item.amount);
    const max = Math.max(...values);
    return values
      .map((value, index) => {
        const x = (index / Math.max(values.length - 1, 1)) * 620;
        const y = 180 - (value / max) * 150;
        return `${x},${y}`;
      })
      .join(" ");
  }, [overview]);

  if (!overview) return <Spinner />;

  const available = overview.stats.totalRaised - overview.stats.totalDistributed;

  return (
    <>
      <PageHero
        eyebrow="Dashboard publik"
        title="Transparansi yang dapat diperiksa siapa saja"
        description="Data dana masuk dan penyaluran diperbarui dari aktivitas campaign. Tidak diperlukan akun untuk mengakses halaman ini."
      >
        <div className="live-line">
          <span className="live-badge">
            <i /> Data aktif
          </span>
          <span>
            <Clock3 size={15} /> Pembaruan terakhir baru saja
          </span>
          <button className="button button-light" onClick={() => window.print()}>
            <ArrowDownToLine size={17} /> Cetak laporan
          </button>
        </div>
      </PageHero>
      <section className="section transparency-dashboard">
        <div className="container">
          <div className="stat-card-grid">
            <article>
              <span className="stat-icon green">
                <CircleDollarSign />
              </span>
              <p>Total dana masuk</p>
              <strong>{rupiah(overview.stats.totalRaised)}</strong>
              <small>Dari seluruh campaign terverifikasi</small>
            </article>
            <article>
              <span className="stat-icon blue">
                <Banknote />
              </span>
              <p>Sudah disalurkan</p>
              <strong>{rupiah(overview.stats.totalDistributed)}</strong>
              <small>
                {Math.round(
                  (overview.stats.totalDistributed / overview.stats.totalRaised) *
                    100,
                )}
                % dari dana masuk
              </small>
            </article>
            <article>
              <span className="stat-icon gold">
                <BadgeCheck />
              </span>
              <p>Saldo tersedia</p>
              <strong>{rupiah(available)}</strong>
              <small>Siap untuk penyaluran berikutnya</small>
            </article>
            <article>
              <span className="stat-icon coral">
                <Users />
              </span>
              <p>Partisipasi publik</p>
              <strong>{overview.stats.donors.toLocaleString("id-ID")}</strong>
              <small>Donatur di {overview.stats.activeCampaigns} campaign aktif</small>
            </article>
          </div>

          <div className="dashboard-grid">
            <article className="panel chart-panel">
              <div className="panel-head">
                <div>
                  <span>Tren donasi</span>
                  <h2>14 hari terakhir</h2>
                </div>
                <span className="verified">
                  <BadgeCheck size={15} /> Tervalidasi
                </span>
              </div>
              <svg viewBox="0 0 620 200" className="line-chart" role="img">
                <defs>
                  <linearGradient id="areaGradient" x1="0" x2="0" y1="0" y2="1">
                    <stop offset="0%" stopColor="#3d8a73" stopOpacity=".3" />
                    <stop offset="100%" stopColor="#3d8a73" stopOpacity="0" />
                  </linearGradient>
                </defs>
                {[30, 80, 130, 180].map((y) => (
                  <line key={y} x1="0" x2="620" y1={y} y2={y} />
                ))}
                <polygon
                  points={`0,180 ${chartPoints} 620,180`}
                  fill="url(#areaGradient)"
                />
                <polyline points={chartPoints} />
              </svg>
              <div className="chart-labels">
                <span>{shortDate(overview.dailyDonations[0].date)}</span>
                <span>
                  {shortDate(
                    overview.dailyDonations[overview.dailyDonations.length - 1].date,
                  )}
                </span>
              </div>
            </article>
            <article className="panel allocation-panel">
              <div className="panel-head">
                <div>
                  <span>Alokasi dana</span>
                  <h2>Status penyaluran</h2>
                </div>
              </div>
              <div className="donut-row">
                <div
                  className="donut"
                  style={{
                    "--percent": `${Math.round(
                      (overview.stats.totalDistributed /
                        overview.stats.totalRaised) *
                        100,
                    ) * 3.6}deg`,
                  } as React.CSSProperties}
                >
                  <span>
                    <b>
                      {Math.round(
                        (overview.stats.totalDistributed /
                          overview.stats.totalRaised) *
                          100,
                      )}
                      %
                    </b>
                    tersalur
                  </span>
                </div>
                <div className="legend-list">
                  <span>
                    <i className="legend-green" /> Tersalur
                    <b>{rupiah(overview.stats.totalDistributed, true)}</b>
                  </span>
                  <span>
                    <i className="legend-gold" /> Tersedia
                    <b>{rupiah(available, true)}</b>
                  </span>
                </div>
              </div>
            </article>
          </div>

          <article className="panel data-panel">
            <div className="panel-head">
              <div>
                <span>Campaign</span>
                <h2>Ringkasan penggalangan dana</h2>
              </div>
            </div>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Campaign</th>
                    <th>Status</th>
                    <th>Target</th>
                    <th>Terkumpul</th>
                    <th>Progress</th>
                    <th>Tersalur</th>
                  </tr>
                </thead>
                <tbody>
                  {overview.campaigns.map((campaign) => (
                    <tr key={campaign.id}>
                      <td>
                        <strong>{campaign.title}</strong>
                        <span>{campaign.location}</span>
                      </td>
                      <td>
                        <StatusBadge status={campaign.status} />
                      </td>
                      <td>{rupiah(campaign.target)}</td>
                      <td>{rupiah(campaign.raised)}</td>
                      <td>
                        <ProgressBar
                          value={campaign.raised}
                          target={campaign.target}
                          color={campaign.accent}
                        />
                        <small>
                          {Math.round((campaign.raised / campaign.target) * 100)}%
                        </small>
                      </td>
                      <td>{rupiah(campaign.distributed)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </article>

          <article className="panel data-panel">
            <div className="panel-head">
              <div>
                <span>Bukti penggunaan dana</span>
                <h2>Riwayat penyaluran terverifikasi</h2>
              </div>
            </div>
            <div className="disbursement-list">
              {overview.disbursements.map((item) => {
                const campaign = overview.campaigns.find(
                  (entry) => entry.id === item.campaignId,
                );
                return (
                  <div key={item.id}>
                    <span className="timeline-dot" />
                    <p>
                      <small>
                        {shortDate(item.date)} - {campaign?.title}
                      </small>
                      <strong>{item.description}</strong>
                      <span>
                        {item.recipient} - {item.evidence}
                      </span>
                    </p>
                    <b>{rupiah(item.amount)}</b>
                  </div>
                );
              })}
            </div>
          </article>
        </div>
      </section>
    </>
  );
}


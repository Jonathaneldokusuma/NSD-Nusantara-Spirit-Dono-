import {
  AlertTriangle,
  BadgeCheck,
  HandHeart,
  HeartPulse,
  House,
  MapPin,
  Utensils,
  Waves,
  X,
  type LucideIcon,
} from "lucide-react";
import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import { rupiah, statusLabel } from "../lib/format";
import type { Campaign } from "../types";

const iconMap: Record<string, LucideIcon> = {
  waves: Waves,
  house: House,
  "heart-pulse": HeartPulse,
  utensils: Utensils,
  "hand-heart": HandHeart,
};

export function Logo({ compact = false }: { compact?: boolean }) {
  return (
    <Link className="brand" to="/">
      <span className="brand-mark">
        <HandHeart size={22} strokeWidth={2.2} />
      </span>
      {!compact && (
        <span>
          <strong>NSD</strong>
          <small>Nusantara Spiritual Donation</small>
        </span>
      )}
    </Link>
  );
}

export function ProgressBar({
  value,
  target,
  color,
}: {
  value: number;
  target: number;
  color?: string;
}) {
  const percentage = Math.min(100, Math.round((value / Math.max(target, 1)) * 100));
  return (
    <div className="progress" aria-label={`Progres ${percentage}%`}>
      <span
        style={{ width: `${percentage}%`, background: color || "var(--green)" }}
      />
    </div>
  );
}

export function StatusBadge({ status }: { status: string }) {
  return (
    <span className={`status-badge status-${status}`}>
      {status === "darurat" && <AlertTriangle size={13} />}
      {statusLabel(status)}
    </span>
  );
}

export function CampaignCard({ campaign }: { campaign: Campaign }) {
  const Icon = iconMap[campaign.icon] || HandHeart;
  const percentage = Math.min(
    100,
    Math.round((campaign.raised / campaign.target) * 100),
  );
  return (
    <article className="campaign-card">
      <Link
        className="campaign-visual"
        style={
          {
            "--campaign-accent": campaign.accent,
          } as React.CSSProperties
        }
        to={`/campaign/${campaign.slug}`}
      >
        <span className="visual-orb orb-one" />
        <span className="visual-orb orb-two" />
        <Icon size={58} strokeWidth={1.35} />
        <StatusBadge status={campaign.status} />
      </Link>
      <div className="campaign-card-body">
        <div className="eyebrow-row">
          <span>{campaign.category}</span>
          {campaign.verified && (
            <span className="verified">
              <BadgeCheck size={14} /> Terverifikasi
            </span>
          )}
        </div>
        <Link className="campaign-title" to={`/campaign/${campaign.slug}`}>
          {campaign.title}
        </Link>
        <p>{campaign.summary}</p>
        <span className="location-line">
          <MapPin size={14} /> {campaign.location}
        </span>
        <ProgressBar
          value={campaign.raised}
          target={campaign.target}
          color={campaign.accent}
        />
        <div className="campaign-numbers">
          <span>
            <strong>{rupiah(campaign.raised, true)}</strong>
            <small>terkumpul</small>
          </span>
          <span className="campaign-percentage">{percentage}%</span>
          <span className="align-right">
            <strong>{rupiah(campaign.target, true)}</strong>
            <small>target</small>
          </span>
        </div>
      </div>
    </article>
  );
}

export function SectionHeading({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow?: string;
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="section-heading">
      <div>
        {eyebrow && <span className="eyebrow">{eyebrow}</span>}
        <h2>{title}</h2>
        {description && <p>{description}</p>}
      </div>
      {action}
    </div>
  );
}

export function Modal({
  open,
  onClose,
  children,
  size = "medium",
}: {
  open: boolean;
  onClose: () => void;
  children: ReactNode;
  size?: "small" | "medium" | "large";
}) {
  if (!open) return null;
  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={onClose}>
      <div
        className={`modal modal-${size}`}
        role="dialog"
        aria-modal="true"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <button className="modal-close" onClick={onClose} aria-label="Tutup">
          <X size={20} />
        </button>
        {children}
      </div>
    </div>
  );
}

export function EmptyState({
  icon: Icon = HandHeart,
  title,
  description,
  action,
}: {
  icon?: LucideIcon;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="empty-state">
      <span>
        <Icon size={28} />
      </span>
      <h3>{title}</h3>
      <p>{description}</p>
      {action}
    </div>
  );
}

export function Spinner() {
  return (
    <div className="page-loader" aria-label="Memuat">
      <span />
    </div>
  );
}


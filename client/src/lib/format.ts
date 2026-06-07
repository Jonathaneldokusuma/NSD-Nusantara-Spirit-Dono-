export function rupiah(value: number, compact = false): string {
  if (compact) {
    return new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 1,
      notation: "compact",
    }).format(value);
  }
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(value);
}

export function shortDate(value: string): string {
  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(value));
}

export function roleLabel(role: string): string {
  const labels: Record<string, string> = {
    donatur: "Donatur",
    pemohon: "Pemohon Bantuan",
    konselor: "Konselor",
    operator: "Operator",
    admin: "Administrator",
    super_admin: "Super Administrator",
  };
  return labels[role] || role;
}

export function statusLabel(status: string): string {
  return status.replaceAll("_", " ").replace(/\b\w/g, (char) => char.toUpperCase());
}


import { Search } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { CampaignCard, Spinner } from "../components/ui";
import { PageHero } from "../components/layout";
import { api } from "../lib/api";
import type { Campaign } from "../types";

export function CampaignListPage() {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("Semua");

  useEffect(() => {
    api<Campaign[]>("/campaigns")
      .then(setCampaigns)
      .finally(() => setLoading(false));
  }, []);

  const categories = useMemo(
    () => ["Semua", ...new Set(campaigns.map((item) => item.category))],
    [campaigns],
  );
  const filtered = campaigns.filter((campaign) => {
    const matchesCategory = category === "Semua" || campaign.category === category;
    const matchesSearch = [campaign.title, campaign.location, campaign.summary]
      .join(" ")
      .toLowerCase()
      .includes(search.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  return (
    <>
      <PageHero
        eyebrow="Campaign bantuan"
        title="Pilih kebutuhan yang ingin Anda kuatkan"
        description="Campaign aktif telah melewati pemeriksaan awal dan terus dipantau oleh tim NSD."
      >
        <div className="campaign-toolbar">
          <label className="search-field">
            <Search size={19} />
            <input
              placeholder="Cari lokasi atau campaign"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
          </label>
        </div>
      </PageHero>
      <section className="section">
        <div className="container">
          <div className="filter-pills">
            {categories.map((item) => (
              <button
                className={category === item ? "active" : ""}
                onClick={() => setCategory(item)}
                key={item}
              >
                {item}
              </button>
            ))}
          </div>
          {loading ? (
            <Spinner />
          ) : (
            <div className="campaign-grid">
              {filtered.map((campaign) => (
                <CampaignCard campaign={campaign} key={campaign.id} />
              ))}
            </div>
          )}
        </div>
      </section>
    </>
  );
}


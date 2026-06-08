import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { createApp } from "./app.js";
import { JsonStore } from "./store.js";

let tempDir: string;
let store: JsonStore;

beforeEach(() => {
  tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "nsd-test-"));
  store = new JsonStore(path.join(tempDir, "data.json"));
});

afterEach(() => {
  fs.rmSync(tempDir, { recursive: true, force: true });
});

describe("NSD API", () => {
  async function login(app: ReturnType<typeof createApp>, email: string) {
    return request(app).post("/api/auth/login").send({
      email,
      password: "Demo1234",
    });
  }

  it("returns public overview", async () => {
    const response = await request(createApp(store)).get(
      "/api/public/overview",
    );
    expect(response.status).toBe(200);
    expect(response.body.campaigns.length).toBeGreaterThan(0);
    expect(response.body.stats.totalRaised).toBeGreaterThan(0);
  });

  it("logs in and completes a donation", async () => {
    const app = createApp(store);
    const donorLogin = await login(app, "donatur@nsd.id");
    expect(donorLogin.status).toBe(200);

    const donation = await request(app)
      .post("/api/donations")
      .set("Authorization", `Bearer ${donorLogin.body.token}`)
      .send({
        campaignId: "cmp-banjir",
        amount: 50_000,
        method: "qris",
        anonymous: false,
        message: "Tetap kuat.",
      });
    expect(donation.status).toBe(201);
    expect(donation.body.status).toBe("pending");

    const confirmation = await request(app)
      .post(`/api/donations/${donation.body.id}/confirm`)
      .set("Authorization", `Bearer ${donorLogin.body.token}`);
    expect(confirmation.status).toBe(200);
    expect(confirmation.body.status).toBe("sukses");
  });

  it("protects admin endpoints from donor accounts", async () => {
    const app = createApp(store);
    const donorLogin = await login(app, "donatur@nsd.id");
    const response = await request(app)
      .get("/api/admin/users")
      .set("Authorization", `Bearer ${donorLogin.body.token}`);
    expect(response.status).toBe(403);
  });

  it("blocks counselors from admin overview", async () => {
    const app = createApp(store);
    const counselorLogin = await login(app, "konselor@nsd.id");

    const response = await request(app)
      .get("/api/admin/overview")
      .set("Authorization", `Bearer ${counselorLogin.body.token}`);

    expect(response.status).toBe(403);
  });

  it("limits counselors to assigned applications and recommendation updates", async () => {
    const app = createApp(store);
    const counselorLogin = await login(app, "konselor@nsd.id");

    const applications = await request(app)
      .get("/api/applications")
      .set("Authorization", `Bearer ${counselorLogin.body.token}`);

    expect(applications.status).toBe(200);
    expect(applications.body).toHaveLength(1);
    expect(applications.body[0].counselorId).toBe("usr-counselor");

    const forbiddenApproval = await request(app)
      .patch(`/api/applications/${applications.body[0].id}`)
      .set("Authorization", `Bearer ${counselorLogin.body.token}`)
      .send({ status: "disetujui" });

    expect(forbiddenApproval.status).toBe(403);

    const recommendation = await request(app)
      .patch(`/api/applications/${applications.body[0].id}`)
      .set("Authorization", `Bearer ${counselorLogin.body.token}`)
      .send({
        status: "direkomendasikan",
        counselorNotes: "Layak direkomendasikan untuk verifikasi admin.",
      });

    expect(recommendation.status).toBe(200);
    expect(recommendation.body.status).toBe("direkomendasikan");
  });
});

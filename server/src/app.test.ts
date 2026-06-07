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
  it("returns public overview", async () => {
    const response = await request(createApp(store)).get("/api/public/overview");
    expect(response.status).toBe(200);
    expect(response.body.campaigns.length).toBeGreaterThan(0);
    expect(response.body.stats.totalRaised).toBeGreaterThan(0);
  });

  it("logs in and completes a donation", async () => {
    const app = createApp(store);
    const login = await request(app).post("/api/auth/login").send({
      email: "donatur@nsd.id",
      password: "Demo1234",
    });
    expect(login.status).toBe(200);

    const donation = await request(app)
      .post("/api/donations")
      .set("Authorization", `Bearer ${login.body.token}`)
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
      .set("Authorization", `Bearer ${login.body.token}`);
    expect(confirmation.status).toBe(200);
    expect(confirmation.body.status).toBe("sukses");
  });

  it("protects admin endpoints from donor accounts", async () => {
    const app = createApp(store);
    const login = await request(app).post("/api/auth/login").send({
      email: "donatur@nsd.id",
      password: "Demo1234",
    });
    const response = await request(app)
      .get("/api/admin/users")
      .set("Authorization", `Bearer ${login.body.token}`);
    expect(response.status).toBe(403);
  });
});


import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import express from "express";
import { Server } from "socket.io";
import { createApp } from "../server/src/app.ts";
import { JsonStore } from "../server/src/store.ts";

const port = Number(process.env.PORT || 4000);
const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const userDist = path.join(rootDir, ".tools", "chrome-user-web");
const counselingDist = path.join(rootDir, ".tools", "chrome-counseling-web");
const adminDist = path.join(rootDir, ".tools", "chrome-admin-web");

function assertBuild(label: string, dir: string) {
  if (!fs.existsSync(path.join(dir, "index.html"))) {
    console.error(`${label} build belum ada: ${dir}`);
    process.exit(1);
  }
}

assertBuild("User", userDist);
assertBuild("Konselor", counselingDist);
assertBuild("Admin", adminDist);

const store = new JsonStore();
let io: Server;
const app = createApp(store, (event, payload) => io?.emit(event, payload));

app.get("/", (_request, response) => response.redirect("/user/"));
app.use("/user", express.static(userDist));
app.get("/user/{*splat}", (_request, response) => {
  response.sendFile(path.join(userDist, "index.html"));
});
app.use("/konselor", express.static(counselingDist));
app.get("/konselor/{*splat}", (_request, response) => {
  response.sendFile(path.join(counselingDist, "index.html"));
});
app.use("/admin", express.static(adminDist));
app.get("/admin/{*splat}", (_request, response) => {
  response.sendFile(path.join(adminDist, "index.html"));
});

const httpServer = http.createServer(app);
io = new Server(httpServer, {
  cors: {
    origin: true,
    credentials: true,
  },
});

io.on("connection", (socket) => {
  socket.emit("connected", { message: "Terhubung ke NSD realtime." });
});

httpServer.listen(port, () => {
  console.log(`NSD API berjalan di http://localhost:${port}`);
  console.log(`App user tersedia di http://localhost:${port}/user/`);
  console.log(`App konselor tersedia di http://localhost:${port}/konselor/`);
  console.log(`Panel admin tersedia di http://localhost:${port}/admin/`);
});

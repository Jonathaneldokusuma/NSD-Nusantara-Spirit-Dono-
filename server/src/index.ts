import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import express from "express";
import { Server } from "socket.io";
import { createApp } from "./app.js";
import { JsonStore } from "./store.js";

const port = Number(process.env.PORT || 4000);
const serverDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const clientDist = path.resolve(serverDir, "..", "client", "build", "web");
const store = new JsonStore();

let io: Server;
const app = createApp(store, (event, payload) => io?.emit(event, payload));

if (fs.existsSync(clientDist)) {
  app.use(express.static(clientDist));
  app.get("/{*splat}", (_request, response) => {
    response.sendFile(path.join(clientDist, "index.html"));
  });
}

const httpServer = http.createServer(app);
io = new Server(httpServer, {
  cors: {
    origin: process.env.CLIENT_ORIGIN || true,
    credentials: true,
  },
});

io.on("connection", (socket) => {
  socket.emit("connected", { message: "Terhubung ke NSD realtime." });
});

httpServer.listen(port, () => {
  console.log(`NSD API berjalan di http://localhost:${port}`);
  if (fs.existsSync(clientDist)) {
    console.log(`NSD web production tersedia di http://localhost:${port}`);
  }
});

import { randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { createSeedDatabase } from "./seed.js";

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
const projectId = process.env.FIREBASE_PROJECT_ID;

if (!serviceAccountJson) {
  throw new Error(
    "FIREBASE_SERVICE_ACCOUNT_JSON belum diisi. Tambahkan service account JSON sebelum menjalankan seed Firestore.",
  );
}

if (!projectId) {
  throw new Error(
    "FIREBASE_PROJECT_ID belum diisi. Gunakan project id Firebase kamu, misalnya nsd-donasi.",
  );
}

if (getApps().length === 0) {
  initializeApp({
    credential: cert(JSON.parse(serviceAccountJson)),
    projectId,
  });
}

const db = getFirestore();
const seed = createSeedDatabase();

async function writeCollection<T extends { id: string }>(
  collectionName: string,
  items: T[],
) {
  const batch = db.batch();
  for (const item of items) {
    const { id, ...data } = item;
    batch.set(db.collection(collectionName).doc(id), {
      id,
      ...data,
      seededAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}

async function main() {
  const orderedCollections = [
    ["users", seed.users],
    ["campaigns", seed.campaigns],
    ["donations", seed.donations],
    ["applications", seed.applications],
    ["sessions", seed.sessions],
    ["disbursements", seed.disbursements],
    ["notifications", seed.notifications],
    ["news", seed.news],
    ["auditLogs", seed.auditLogs],
  ] as const;

  for (const [collectionName, items] of orderedCollections) {
    const snapshot = await db.collection(collectionName).get();
    const batchSize = 400;
    for (let index = 0; index < snapshot.size; index += batchSize) {
      const batch = db.batch();
      for (const doc of snapshot.docs.slice(index, index + batchSize)) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }
    if (items.length > 0) {
      await writeCollection(collectionName, items as never[]);
    }
  }

  const metaRef = db.collection("meta").doc("seed");
  await metaRef.set({
    id: randomUUID(),
    createdAt: new Date().toISOString(),
    source: resolve(process.cwd(), "server/src/seed-firestore.ts"),
    note: "Seed demo NSD berhasil ditulis ke Firestore.",
  });

  console.log(`Firestore seed selesai untuk project ${projectId}.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

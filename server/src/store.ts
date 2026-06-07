import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createSeedDatabase } from "./seed.js";
import type { Database } from "./types.js";

const packageDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

export class JsonStore {
  readonly filePath: string;
  private data: Database;

  constructor(filePath = process.env.DATA_FILE || path.join(packageDir, "data", "nsd.json")) {
    this.filePath = filePath;
    this.data = this.load();
  }

  private load(): Database {
    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    if (!fs.existsSync(this.filePath)) {
      const seed = createSeedDatabase();
      fs.writeFileSync(this.filePath, JSON.stringify(seed, null, 2));
      return seed;
    }
    return JSON.parse(fs.readFileSync(this.filePath, "utf8")) as Database;
  }

  read(): Database {
    return this.data;
  }

  update(mutator: (database: Database) => void): Database {
    mutator(this.data);
    fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2));
    return this.data;
  }

  reset(): Database {
    this.data = createSeedDatabase();
    fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2));
    return this.data;
  }
}


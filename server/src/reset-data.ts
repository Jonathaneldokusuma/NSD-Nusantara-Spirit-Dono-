import { JsonStore } from "./store.js";

const store = new JsonStore();
store.reset();
console.log(`Data demo direset: ${store.filePath}`);


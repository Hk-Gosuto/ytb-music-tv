import { join } from 'node:path';

import { createJsonStore } from './json-store.js';

const defaults = {
  poToken: '',
  visitorData: '',
  updatedAt: null,
};

export const loadSessionStore = async (dataDir) =>
  await createJsonStore(join(dataDir, 'session.json'), defaults);

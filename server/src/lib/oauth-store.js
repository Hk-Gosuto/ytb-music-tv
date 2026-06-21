import { unwatchFile, watchFile } from 'node:fs';
import { join } from 'node:path';

import { createJsonStore } from './json-store.js';

const defaults = {
  accessToken: '',
  refreshToken: '',
  expiresAt: null,
  refreshTokenExpiresAt: null,
  tokenType: 'Bearer',
  scope: '',
  updatedAt: null,
};

export const loadOAuthStore = async (dataDir, options = {}) => {
  const path = join(dataDir, 'oauth.json');
  const store = await createJsonStore(path, defaults, { mode: 0o600 });

  if (options.watch) {
    const listener = (current, previous) => {
      if (current.mtimeMs === previous.mtimeMs) return;
      store.reload().catch((error) => {
        console.warn(`Unable to reload Google OAuth credentials: ${error?.message ?? error}`);
      });
    };
    watchFile(path, { interval: 500, persistent: false }, listener);
    store.close = () => unwatchFile(path, listener);
  } else {
    store.close = () => {};
  }

  return store;
};

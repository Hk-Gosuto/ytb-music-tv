#!/usr/bin/env node

import { runOAuthLoginFlow } from '../lib/oauth-login-flow.js';
import { loadOAuthStore } from '../lib/oauth-store.js';
import {
  GoogleOAuthClient,
  oauthConfigFromEnv,
} from '../services/google-oauth.js';

const dataDir = process.env.YTB_MUSIC_TV_DATA_DIR ?? new URL('../../data', import.meta.url).pathname;
const store = await loadOAuthStore(dataDir);
const oauth = new GoogleOAuthClient({
  store,
  ...oauthConfigFromEnv(),
});

try {
  await runOAuthLoginFlow({ oauth, dataDir });
} catch (error) {
  console.error(`Google OAuth login failed: ${error?.message ?? error}`);
  process.exitCode = 1;
}

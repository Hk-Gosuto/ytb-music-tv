#!/usr/bin/env node

import { join } from 'node:path';

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
  await oauth.login({
    onCode: ({ userCode, verificationUrl, verificationUrlComplete }) => {
      console.log('Open this URL in a browser and authorize YTB Music TV:');
      console.log(verificationUrlComplete ?? verificationUrl);
      console.log(`Device code: ${userCode}`);
      console.log('Waiting for authorization...');
    },
  });
  console.log(`Google OAuth login completed. Credentials saved to ${join(dataDir, 'oauth.json')}`);
} catch (error) {
  console.error(`Google OAuth login failed: ${error?.message ?? error}`);
  process.exitCode = 1;
}

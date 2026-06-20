import { createServer } from 'node:http';
import { hostname } from 'node:os';

import { loadConfig } from './lib/config.js';
import { startDiscoveryServer } from './lib/discovery.js';
import { createApiRouter } from './lib/router.js';
import { loadSessionStore } from './lib/session-store.js';
import { YouTubeMusicService } from './services/youtube-service.js';

const host = process.env.YTB_MUSIC_TV_HOST ?? '127.0.0.1';
const port = Number.parseInt(process.env.YTB_MUSIC_TV_PORT ?? '4174', 10);
const discoveryPort = Number.parseInt(process.env.YTB_MUSIC_TV_DISCOVERY_PORT ?? '4175', 10);
const dataDir = process.env.YTB_MUSIC_TV_DATA_DIR ?? new URL('../data', import.meta.url).pathname;
const serverName = process.env.YTB_MUSIC_TV_SERVER_NAME ?? hostname();

const configStore = await loadConfig(dataDir);
const sessionStore = await loadSessionStore(dataDir);
const youtubeService = new YouTubeMusicService({ configStore, sessionStore });
const router = createApiRouter({
  configStore,
  youtubeService,
  serverName,
});
const config = configStore.get();

startDiscoveryServer({
  discoveryPort,
  servicePort: port,
  serverId: config.security.serverId,
  serverName,
});

const server = createServer((req, res) => {
  router(req, res).catch((error) => {
    console.error(error);
    if (!res.headersSent) {
      res.writeHead(500, { 'content-type': 'application/json; charset=utf-8' });
    }
    res.end(JSON.stringify({ error: 'internal_error', message: String(error?.message ?? error) }));
  });
});

server.listen(port, host, () => {
  console.log(`YTB Music TV server listening on http://${host}:${port}`);
  console.log(`YTB Music TV device code: ${config.security.deviceCode}`);
});

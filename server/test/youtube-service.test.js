import assert from 'node:assert/strict';
import test from 'node:test';

import {
  libraryFromParsedResponse,
  YouTubeMusicService,
} from '../src/services/youtube-service.js';

test('uses the OAuth-backed YouTube TV service for Library', async () => {
  const expected = {
    provider: 'youtube-music-tv-oauth',
    filters: [],
    sortOptions: [],
    sections: [],
  };
  const service = new YouTubeMusicService({
    configStore: { get: () => ({ youtube: {} }) },
    sessionStore: sessionStore(),
    oauthLibraryService: {
      authStatus: () => ({ status: 'configured', hasRefreshToken: true }),
      library: async () => expected,
    },
  });

  assert.equal(service.authStatus().mode, 'google-device-oauth');
  assert.deepEqual(await service.library(), expected);
});

const sessionStore = () => ({
  get: () => ({ poToken: '', visitorData: '', updatedAt: null }),
  patch: async () => {},
  clear: async () => {},
});

test('normalizes an empty ItemSection library response', () => {
  const parsed = {
    contents_memo: {
      getType: () => [],
    },
  };

  assert.deepEqual(libraryFromParsedResponse(parsed), {
    filters: [],
    sortOptions: [],
    sections: [],
  });
});

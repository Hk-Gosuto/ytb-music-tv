import test from 'node:test';
import assert from 'node:assert/strict';

import { isBlockedUrl } from '../src/features/adblock.js';

const config = {
  enabled: true,
  blockedHosts: ['doubleclick.net', 'ads.example.test'],
};

test('isBlockedUrl blocks exact and subdomain matches', () => {
  assert.equal(isBlockedUrl('https://doubleclick.net/pagead', config), true);
  assert.equal(isBlockedUrl('https://foo.doubleclick.net/pagead', config), true);
  assert.equal(isBlockedUrl('https://ads.example.test/file.js', config), true);
});

test('isBlockedUrl allows unrelated hosts', () => {
  assert.equal(isBlockedUrl('https://music.youtube.com/watch?v=1', config), false);
});

test('isBlockedUrl treats malformed URLs as blocked', () => {
  assert.equal(isBlockedUrl('not a url', config), true);
});

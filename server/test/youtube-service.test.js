import assert from 'node:assert/strict';
import test from 'node:test';

import { libraryFromParsedResponse } from '../src/services/youtube-service.js';

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

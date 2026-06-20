import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';

export const createJsonStore = async (path, defaults) => {
  await mkdir(dirname(path), { recursive: true });

  let current = structuredClone(defaults);
  try {
    current = {
      ...current,
      ...JSON.parse(await readFile(path, 'utf8')),
    };
  } catch (error) {
    if (error?.code !== 'ENOENT') {
      throw error;
    }
    await writeFile(path, `${JSON.stringify(current, null, 2)}\n`);
  }

  const save = async () => {
    await writeFile(path, `${JSON.stringify(current, null, 2)}\n`);
  };

  return {
    get: () => structuredClone(current),
    set: async (next) => {
      current = structuredClone(next);
      await save();
      return structuredClone(current);
    },
    patch: async (patch) => {
      current = {
        ...current,
        ...structuredClone(patch),
      };
      await save();
      return structuredClone(current);
    },
    clear: async () => {
      current = structuredClone(defaults);
      await save();
      return structuredClone(current);
    },
  };
};

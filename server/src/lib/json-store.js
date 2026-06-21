import { chmod, mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';

export const createJsonStore = async (path, defaults, options = {}) => {
  const mode = options.mode;
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
    await writeJson(path, current, mode);
  }

  const save = async () => {
    await writeJson(path, current, mode);
  };

  const reload = async () => {
    current = {
      ...structuredClone(defaults),
      ...JSON.parse(await readFile(path, 'utf8')),
    };
    return structuredClone(current);
  };

  return {
    get: () => structuredClone(current),
    reload,
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

const writeJson = async (path, value, mode) => {
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`, mode == null ? undefined : { mode });
  if (mode != null) {
    await chmod(path, mode);
  }
};

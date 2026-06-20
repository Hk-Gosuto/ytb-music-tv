import { createHash, randomBytes, randomUUID } from 'node:crypto';

export const issueClientToken = async (configStore, {
  name = 'Apple TV',
  deviceCode = '',
}) => {
  const config = configStore.get();
  const submittedCode = String(deviceCode).trim();
  const clientName = String(name).trim().slice(0, 80) || 'Apple TV';

  if (!config.security?.deviceCode || submittedCode !== config.security.deviceCode) {
    const error = new Error('Invalid device code');
    error.status = 403;
    throw error;
  }

  const token = `ytbmtv_${randomBytes(32).toString('base64url')}`;
  const client = {
    id: randomUUID(),
    name: clientName,
    tokenHash: hashToken(token),
    createdAt: new Date().toISOString(),
    lastUsedAt: null,
  };

  config.security.clients = [...(config.security.clients ?? []), client];
  await configStore.replace(config);

  return {
    token,
    client: {
      id: client.id,
      name: client.name,
      createdAt: client.createdAt,
    },
  };
};

export const clientForRequest = (configStore, req) => {
  const config = configStore.get();
  const header = req.headers.authorization ?? '';
  const token = header.startsWith('Bearer ') ? header.slice('Bearer '.length) : '';
  if (!token) {
    return null;
  }

  const tokenHash = hashToken(token);
  const clients = config.security.clients ?? [];
  return clients.find((client) => client.tokenHash === tokenHash) ?? null;
};

const hashToken = (token) => createHash('sha256').update(token).digest('hex');

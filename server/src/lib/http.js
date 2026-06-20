export const json = (res, status, body, headers = {}) => {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    ...headers,
  });
  res.end(JSON.stringify(body));
};

export const notFound = (res) => {
  json(res, 404, { error: 'not_found' });
};

export const methodNotAllowed = (res) => {
  json(res, 405, { error: 'method_not_allowed' });
};

export const readJson = async (req) => {
  const text = (await readText(req)).trim();
  if (!text) {
    return {};
  }

  return JSON.parse(text);
};

export const readText = async (req) => {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }

  if (chunks.length === 0) {
    return '';
  }

  return Buffer.concat(chunks).toString('utf8');
};

export const parseRequestUrl = (req) => {
  const host = req.headers.host ?? '127.0.0.1';
  return new URL(req.url ?? '/', `http://${host}`);
};

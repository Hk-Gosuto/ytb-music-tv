import { join } from 'node:path';

export const runOAuthLoginFlow = async ({ oauth, dataDir, logger = console } = {}) => {
  await oauth.login({
    onCode: ({ userCode, verificationUrl, verificationUrlComplete }) => {
      logger.log([
        'Open this URL in a browser and authorize YTB Music TV:',
        verificationUrlComplete ?? verificationUrl,
        `Device code: ${userCode}`,
        'Waiting for authorization...',
      ].join('\n'));
    },
  });

  logger.log(`Google OAuth login completed. Credentials saved to ${join(dataDir, 'oauth.json')}`);
};

export const startOAuthLoginFlow = ({ oauth, dataDir, logger = console } = {}) => {
  runOAuthLoginFlow({ oauth, dataDir, logger }).catch((error) => {
    logger.error(`Google OAuth login failed: ${error?.message ?? error}`);
  });
};

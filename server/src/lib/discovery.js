import { createSocket } from 'node:dgram';

export const discoveryRequest = 'ytb-music-tv:discover:v1';

export const startDiscoveryServer = ({
  discoveryPort = 4175,
  servicePort,
  serverId,
  serverName,
}) => {
  const socket = createSocket({ type: 'udp4', reuseAddr: true });

  socket.on('message', (message, remote) => {
    if (message.toString('utf8').trim() !== discoveryRequest) {
      return;
    }

    const response = Buffer.from(JSON.stringify({
      service: 'ytb-music-tv-server',
      version: 1,
      id: serverId,
      name: serverName,
      port: servicePort,
    }));
    socket.send(response, remote.port, remote.address);
  });

  socket.on('error', (error) => {
    console.error(`YTB Music TV discovery error: ${error.message}`);
  });

  socket.bind(discoveryPort, '0.0.0.0', () => {
    console.log(`YTB Music TV discovery listening on udp://0.0.0.0:${discoveryPort}`);
  });

  return socket;
};

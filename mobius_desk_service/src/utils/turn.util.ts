import * as crypto from 'crypto';

export function generateTurnCredentials(
  username: string,
  secret: string,
  ttl: number = 86400,
): { username: string; credential: string } {
  const timestamp = Math.floor(Date.now() / 1000) + ttl;
  const turnUsername = `${timestamp}:${username}`;
  const hmac = crypto.createHmac('sha1', secret);
  hmac.update(turnUsername);
  const credential = hmac.digest('base64');
  return { username: turnUsername, credential };
}
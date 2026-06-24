import { registerAs } from '@nestjs/config';

export default registerAs('coturn', () => ({
  url: process.env.COTURN_URL || '',
  username: process.env.COTURN_USERNAME || 'mobius',
  password: process.env.COTURN_PASSWORD || '',
}));
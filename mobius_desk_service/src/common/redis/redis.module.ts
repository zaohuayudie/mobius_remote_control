import { Module, Global, Logger } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: 'REDIS_CLIENT',
      useFactory: (configService: ConfigService) => {
        const logger = new Logger('RedisModule');
        const host = configService.get<string>('redis.host');
        const port = configService.get<number>('redis.port');
        const password = configService.get<string>('redis.password') || undefined;

        const redis = new Redis({
          host,
          port,
          password,
          retryStrategy(times) {
            const delay = Math.min(times * 500, 5000);
            logger.warn(`Retry connection #${times}, next attempt in ${delay}ms`);
            return delay;
          },
          maxRetriesPerRequest: 3,
          enableReadyCheck: true,
          lazyConnect: false,
        });

        redis.on('connect', () => {
          logger.log(`Connected to ${host}:${port}`);
        });

        redis.on('ready', () => {
          logger.log('Redis is ready to accept commands');
        });

        redis.on('error', (err) => {
          logger.error(`Redis error: ${err.message}`, err.stack);
        });

        redis.on('close', () => {
          logger.warn('Redis connection closed');
        });

        redis.on('reconnecting', () => {
          logger.log('Reconnecting to Redis...');
        });

        return redis;
      },
      inject: [ConfigService],
    },
  ],
  exports: ['REDIS_CLIENT'],
})
export class RedisModule {}

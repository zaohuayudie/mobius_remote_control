import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  private logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction) {
    const { method, originalUrl, ip } = req;
    const userAgent = req.get('user-agent') || '';
    const deviceUuid = (req as any).deviceUuid || req.headers['x-device-uuid'] || '-';
    const startTime = Date.now();

    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const { statusCode } = res;
      const log = `[${deviceUuid}] ${method} ${originalUrl} ${statusCode} ${duration}ms ${ip} ${userAgent}`;
      if (statusCode >= 500) {
        this.logger.error(log);
      } else if (statusCode >= 400) {
        this.logger.warn(log);
      } else {
        this.logger.log(log);
      }
    });

    next();
  }
}
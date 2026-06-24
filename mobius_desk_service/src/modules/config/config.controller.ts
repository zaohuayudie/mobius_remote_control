import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { generateTurnCredentials } from '../../utils/turn.util';

@ApiTags('配置')
@Controller('api/v1/config')
export class ConfigController {
  constructor(private configService: ConfigService) {}

  @Get('ice-servers')
  @ApiOperation({ summary: '获取ICE服务器配置(含TURN凭据)' })
  async getIceServers() {
    const coturnUrl = this.configService.get<string>('coturn.url');
    const coturnUsername = this.configService.get<string>('coturn.username');
    const coturnPassword = this.configService.get<string>('coturn.password');

    const iceServers: any[] = [
      { urls: 'stun:stun.l.google.com:19302' },
    ];

    if (coturnUrl && coturnPassword) {
      const credentials = generateTurnCredentials(
        coturnUsername || 'mobius',
        coturnPassword,
      );
      iceServers.push({
        urls: coturnUrl,
        username: credentials.username,
        credential: credentials.credential,
      });
    }

    return { iceServers };
  }
}
import { Injectable, Inject } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Device, DeviceDocument } from '../devices/schemas/device.schema';
import { comparePassword } from '../../utils/crypto.util';
import Redis from 'ioredis';

@Injectable()
export class DeskService {
  constructor(
    @InjectModel(Device.name) private deviceModel: Model<DeviceDocument>,
    private jwtService: JwtService,
    private configService: ConfigService,
    @Inject('REDIS_CLIENT') private redis: Redis,
  ) {}

  async verifyToken(token: string) {
    return this.jwtService.verifyAsync(token, {
      secret: this.configService.get<string>('jwt.secret'),
    });
  }

  async verifyDevice(uuid: string, password: string): Promise<boolean> {
    const device = await this.deviceModel.findOne({ uuid }).lean();
    if (!device) return false;
    return comparePassword(password, device.password);
  }

  async handleStartRemote(
    client: any,
    data: {
      controller_uuid: string;
      target_uuid: string;
      target_password: string;
      max_bitrate?: number;
      max_framerate?: number;
      resolution?: string;
      video_hint?: string;
      audio_hint?: string;
    },
  ) {
    if (!data.controller_uuid || !data.target_uuid) {
      return { code: 1, message: '参数为空' };
    }

    const controllerSocketId = await this.redis.get(
      `mobius:device:uuid:${data.controller_uuid}`,
    );
    if (!controllerSocketId) {
      return { code: 2, message: '主控端不在线' };
    }

    const targetValid = await this.verifyDevice(
      data.target_uuid,
      data.target_password,
    );
    if (!targetValid) {
      return { code: 3, message: '被控端密码错误' };
    }

    const targetOnline = await this.redis.exists(
      `mobius:device:uuid:${data.target_uuid}`,
    );
    if (!targetOnline) {
      return { code: 4, message: '被控端不在线' };
    }

    const targetSocketId = await this.redis.get(
      `mobius:device:uuid:${data.target_uuid}`,
    );

    return {
      code: 0,
      message: 'success',
      controller: { uuid: data.controller_uuid, socket_id: controllerSocketId },
      target: { uuid: data.target_uuid, socket_id: targetSocketId },
    };
  }
}
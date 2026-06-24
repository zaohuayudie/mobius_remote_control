import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Device, DeviceDocument } from './schemas/device.schema';
import { CreateDeviceDto } from './dto/create-device.dto';
import { LoginDeviceDto } from './dto/login-device.dto';
import { VerifyDeviceDto } from './dto/verify-device.dto';
import { generateUuid, generateDevicePassword } from '../../utils/uuid.util';
import { hashPassword, comparePassword } from '../../utils/crypto.util';
import { Inject } from '@nestjs/common';
import Redis from 'ioredis';

@Injectable()
export class DevicesService {
  constructor(
    @InjectModel(Device.name) private deviceModel: Model<DeviceDocument>,
    @Inject('REDIS_CLIENT') private redis: Redis,
  ) {}

  async create(createDeviceDto: CreateDeviceDto) {
    const uuid = generateUuid();
    const rawPassword = generateDevicePassword();
    const hashedPassword = await hashPassword(rawPassword);

    let userId = null;
    if (createDeviceDto.username) {
      const user = await this.deviceModel.db
        .model('User')
        .findOne({ username: createDeviceDto.username });
      if (user) {
        userId = user._id;
      }
    }

    const device = await this.deviceModel.create({
      uuid,
      password: hashedPassword,
      user_id: userId,
    });

    return {
      id: device._id,
      uuid: device.uuid,
      password: rawPassword,
    };
  }

  async login(loginDeviceDto: LoginDeviceDto) {
    const device = await this.deviceModel.findOne({
      uuid: loginDeviceDto.uuid,
    });
    if (!device) {
      throw new NotFoundException('设备不存在');
    }

    if (device.status === 1) {
      throw new UnauthorizedException('设备已被禁用');
    }

    const isPasswordValid = await comparePassword(
      loginDeviceDto.password,
      device.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('设备密码错误');
    }

    return {
      id: device._id,
      uuid: device.uuid,
    };
  }

  async verify(verifyDeviceDto: VerifyDeviceDto) {
    const device = await this.deviceModel.findOne({
      uuid: verifyDeviceDto.uuid,
    });
    if (!device) {
      return { valid: false };
    }

    const isPasswordValid = await comparePassword(
      verifyDeviceDto.password,
      device.password,
    );

    return { valid: isPasswordValid };
  }

  async updatePassword(uuid: string, newPassword: string, oldPassword?: string) {
    const device = await this.deviceModel.findOne({ uuid });
    if (!device) {
      throw new NotFoundException('设备不存在');
    }

    if (oldPassword) {
      const isOldPasswordValid = await comparePassword(oldPassword, device.password);
      if (!isOldPasswordValid) {
        throw new UnauthorizedException('设备旧密码错误');
      }
    }

    const hashedPassword = await hashPassword(newPassword);
    await this.deviceModel.updateOne({ uuid }, { password: hashedPassword });
    return null;
  }

  async checkOnline(uuid: string) {
    const exists = await this.redis.exists(`mobius:device:uuid:${uuid}`);
    return { online: exists === 1 };
  }

  async findByUuid(uuid: string) {
    return this.deviceModel.findOne({ uuid }).lean();
  }

  async findAllOnline() {
    const keys = await this.redis.keys('mobius:device:uuid:*');
    if (keys.length === 0) return [];

    const onlineUuids = keys.map((key) => key.replace('mobius:device:uuid:', ''));

    const devices = await this.deviceModel
      .find({ uuid: { $in: onlineUuids }, status: 0 })
      .select('uuid created_at')
      .lean();

    return devices.map((device) => ({
      uuid: device.uuid,
      online: true,
      created_at: device.created_at,
    }));
  }
}
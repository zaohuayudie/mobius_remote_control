import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DeskGateway } from './desk.gateway';
import { DeskService } from './desk.service';
import { Device, DeviceSchema } from '../devices/schemas/device.schema';
import { AuthModule } from '../auth/auth.module';
import { RedisModule } from '../../common/redis/redis.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Device.name, schema: DeviceSchema }]),
    AuthModule,
    RedisModule,
  ],
  providers: [DeskGateway, DeskService],
})
export class DeskModule {}
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VersionsController } from './versions.controller';
import { VersionsService } from './versions.service';
import { Version, VersionSchema } from './schemas/version.schema';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Version.name, schema: VersionSchema }]),
    AuthModule,
  ],
  controllers: [VersionsController],
  providers: [VersionsService],
  exports: [VersionsService],
})
export class VersionsModule {}
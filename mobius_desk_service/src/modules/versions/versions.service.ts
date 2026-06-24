import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Version, VersionDocument } from './schemas/version.schema';

@Injectable()
export class VersionsService {
  constructor(
    @InjectModel(Version.name) private versionModel: Model<VersionDocument>,
  ) {}

  async checkUpdate(platform: string, currentVersion: string) {
    const validPlatforms = ['win', 'mac', 'linux', 'android'];
    if (!validPlatforms.includes(platform)) {
      throw new BadRequestException('无效的平台参数');
    }

    const latestVersion = await this.versionModel
      .findOne()
      .sort({ created_at: -1 })
      .lean();

    if (!latestVersion) {
      return {
        hasUpdate: false,
        force: false,
        version: currentVersion,
        content: null,
        downloadUrl: null,
      };
    }

    const hasUpdate = this.compareVersions(latestVersion.version, currentVersion) > 0;
    const downloadField = `download_${platform}`;
    const downloadUrl = (latestVersion as any)[downloadField] || null;

    return {
      hasUpdate,
      force: latestVersion.force === 1,
      version: latestVersion.version,
      content: latestVersion.content,
      downloadUrl,
    };
  }

  async create(createVersionDto: any) {
    const version = await this.versionModel.create(createVersionDto);
    return version;
  }

  private compareVersions(v1: string, v2: string): number {
    const parts1 = v1.split('.').map(Number);
    const parts2 = v2.split('.').map(Number);
    const maxLength = Math.max(parts1.length, parts2.length);

    for (let i = 0; i < maxLength; i++) {
      const p1 = parts1[i] || 0;
      const p2 = parts2[i] || 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}
import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { VersionsService } from './versions.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateVersionDto } from './dto/create-version.dto';

@ApiTags('版本')
@Controller('api/v1/versions')
export class VersionsController {
  constructor(private readonly versionsService: VersionsService) {}

  @Get('check')
  @ApiOperation({ summary: '检查版本更新' })
  async checkUpdate(
    @Query('platform') platform: string,
    @Query('version') version: string,
  ) {
    return this.versionsService.checkUpdate(platform, version);
  }

  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: '创建版本' })
  async create(@Body() createVersionDto: CreateVersionDto) {
    return this.versionsService.create(createVersionDto);
  }
}
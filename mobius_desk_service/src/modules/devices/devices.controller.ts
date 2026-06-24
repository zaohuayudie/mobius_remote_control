import {
  Controller,
  Post,
  Put,
  Get,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { DevicesService } from './devices.service';
import { CreateDeviceDto } from './dto/create-device.dto';
import { LoginDeviceDto } from './dto/login-device.dto';
import { VerifyDeviceDto } from './dto/verify-device.dto';
import { UpdateDevicePasswordDto } from './dto/update-device-password.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('设备')
@Controller('api/v1/devices')
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Get()
  @ApiOperation({ summary: '获取在线设备列表' })
  async findAll() {
    return this.devicesService.findAllOnline();
  }

  @Post()
  @ApiOperation({ summary: '注册设备' })
  async create(@Body() createDeviceDto: CreateDeviceDto) {
    return this.devicesService.create(createDeviceDto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '设备登录' })
  async login(@Body() loginDeviceDto: LoginDeviceDto) {
    return this.devicesService.login(loginDeviceDto);
  }

  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '连接验证' })
  async verify(@Body() verifyDeviceDto: VerifyDeviceDto) {
    return this.devicesService.verify(verifyDeviceDto);
  }

  @Put(':uuid/password')
  // @ApiBearerAuth()
  // @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: '更新设备密码' })
  async updatePassword(
    @Param('uuid') uuid: string,
    @Body() updateDevicePasswordDto: UpdateDevicePasswordDto,
  ) {
    return this.devicesService.updatePassword(uuid, updateDevicePasswordDto.password, updateDevicePasswordDto.oldPassword);
  }

  @Get(':uuid/online')
  @ApiOperation({ summary: '查询设备是否在线' })
  async checkOnline(@Param('uuid') uuid: string) {
    return this.devicesService.checkOnline(uuid);
  }
}
import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../users/schemas/user.schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { hashPassword, comparePassword } from '../../utils/crypto.util';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    const existing = await this.userModel.findOne({
      username: registerDto.username,
    });
    if (existing) {
      throw new ConflictException('用户名已存在');
    }

    const hashedPassword = await hashPassword(registerDto.password);
    const user = await this.userModel.create({
      username: registerDto.username,
      password: hashedPassword,
    });

    return {
      id: user._id,
      username: user.username,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.userModel.findOne({
      username: loginDto.username,
    });
    if (!user) {
      throw new UnauthorizedException('用户名或密码错误');
    }

    if (user.status === 1) {
      throw new UnauthorizedException('账号已被禁用');
    }

    const isPasswordValid = await comparePassword(
      loginDto.password,
      user.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('用户名或密码错误');
    }

    const payload = { sub: user._id, username: user.username };
    const token = this.jwtService.sign(payload);

    return {
      token,
      user: {
        id: user._id,
        username: user.username,
      },
    };
  }
}
import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from './schemas/user.schema';
import { UpdateUserDto } from './dto/update-user.dto';
import { hashPassword } from '../../utils/crypto.util';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async findById(id: string) {
    const user = await this.userModel.findById(id).select('-password').lean();
    if (!user) {
      throw new NotFoundException('用户不存在');
    }
    return user;
  }

  async findByUsername(username: string) {
    return this.userModel.findOne({ username }).lean();
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    const updateData: any = {};
    if (updateUserDto.password) {
      updateData.password = await hashPassword(updateUserDto.password);
    }

    const user = await this.userModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .select('-password')
      .lean();

    if (!user) {
      throw new NotFoundException('用户不存在');
    }
    return user;
  }
}
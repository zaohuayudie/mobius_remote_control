import { IsString, IsOptional } from 'class-validator';

export class CreateDeviceDto {
  @IsOptional()
  @IsString()
  username?: string;
}
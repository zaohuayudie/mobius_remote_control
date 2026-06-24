import { IsString, MinLength, MaxLength } from 'class-validator';

export class UpdateDevicePasswordDto {
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  password: string;

  @IsString()
  @MinLength(1)
  oldPassword: string;
}

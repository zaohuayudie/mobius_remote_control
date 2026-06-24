import { IsString, MinLength } from 'class-validator';

export class VerifyDeviceDto {
  @IsString()
  @MinLength(1)
  uuid: string;

  @IsString()
  @MinLength(1)
  password: string;
}
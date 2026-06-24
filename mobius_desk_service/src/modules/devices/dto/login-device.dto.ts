import { IsString, MinLength } from 'class-validator';

export class LoginDeviceDto {
  @IsString()
  @MinLength(1)
  uuid: string;

  @IsString()
  @MinLength(1)
  password: string;
}
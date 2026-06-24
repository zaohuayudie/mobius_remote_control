import { IsString, IsNumber, IsOptional, MaxLength } from 'class-validator';

export class CreateVersionDto {
  @IsString()
  @MaxLength(32)
  version: string;

  @IsNumber()
  force: number;

  @IsOptional()
  @IsString()
  content?: string;

  @IsOptional()
  @IsString()
  @MaxLength(512)
  download_win?: string;

  @IsOptional()
  @IsString()
  @MaxLength(512)
  download_mac?: string;

  @IsOptional()
  @IsString()
  @MaxLength(512)
  download_linux?: string;

  @IsOptional()
  @IsString()
  @MaxLength(512)
  download_android?: string;
}
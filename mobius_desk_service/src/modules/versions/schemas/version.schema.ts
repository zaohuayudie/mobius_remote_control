import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type VersionDocument = Version & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'versions',
})
export class Version {
  @Prop({ required: true, maxlength: 32 })
  version: string;

  @Prop({ required: true, default: 0, enum: [0, 1] })
  force: number;

  @Prop({ default: null })
  content: string;

  @Prop({ default: null, maxlength: 512 })
  download_win: string;

  @Prop({ default: null, maxlength: 512 })
  download_mac: string;

  @Prop({ default: null, maxlength: 512 })
  download_linux: string;

  @Prop({ default: null, maxlength: 512 })
  download_android: string;

  @Prop()
  created_at: Date;

  @Prop()
  updated_at: Date;
}

export const VersionSchema = SchemaFactory.createForClass(Version);
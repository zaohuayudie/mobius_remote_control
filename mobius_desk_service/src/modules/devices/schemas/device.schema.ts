import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export type DeviceDocument = Device & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'devices',
})
export class Device {
  @Prop({ required: true, unique: true, trim: true, maxlength: 64 })
  uuid: string;

  @Prop({ required: true })
  password: string;

  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'users', default: null })
  user_id: string;

  @Prop({ required: true, default: 0, enum: [0, 1] })
  status: number;

  @Prop()
  created_at: Date;

  @Prop()
  updated_at: Date;
}

export const DeviceSchema = SchemaFactory.createForClass(Device);
DeviceSchema.index({ uuid: 1 }, { unique: true });
DeviceSchema.index({ user_id: 1 });
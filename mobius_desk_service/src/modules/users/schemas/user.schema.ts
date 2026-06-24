import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'users',
})
export class User {
  @Prop({ required: true, unique: true, trim: true, maxlength: 64 })
  username: string;

  @Prop({ required: true })
  password: string;

  @Prop({ required: true, default: 0, enum: [0, 1] })
  status: number;

  @Prop()
  created_at: Date;

  @Prop()
  updated_at: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
UserSchema.index({ username: 1 }, { unique: true });
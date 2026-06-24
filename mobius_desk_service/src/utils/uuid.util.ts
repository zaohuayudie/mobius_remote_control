import { v4 as uuidv4 } from 'uuid';

export function generateUuid(): string {
  return uuidv4();
}

export function generateDevicePassword(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}
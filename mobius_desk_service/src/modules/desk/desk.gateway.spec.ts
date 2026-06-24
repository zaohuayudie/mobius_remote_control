import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule } from '@nestjs/config';
import { io, Socket } from 'socket.io-client';
import * as jwt from 'jsonwebtoken';
import { DeskGateway } from './desk.gateway';
import { DeskService } from './desk.service';
import { Device, DeviceSchema } from '../devices/schemas/device.schema';

describe('DeskGateway (WebSocket)', () => {
  let app: INestApplication;
  let clientSocket: Socket;
  let targetSocket: Socket;
  const port = 4299;

  const mockRedis = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
    exists: jest.fn().mockResolvedValue(1),
    hset: jest.fn(),
    expire: jest.fn(),
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          load: [
            () => ({
              database: {
                uri: process.env.MONGO_TEST_URI || 'mongodb://localhost:27017/mobius_desk_test',
              },
              jwt: { secret: 'test-secret', expiresIn: '1h' },
            }),
          ],
        }),
        MongooseModule.forRoot(process.env.MONGO_TEST_URI || 'mongodb://localhost:27017/mobius_desk_test'),
        MongooseModule.forFeature([{ name: Device.name, schema: DeviceSchema }]),
        JwtModule.register({ secret: 'test-secret', signOptions: { expiresIn: '1h' } }),
      ],
      providers: [
        DeskGateway,
        DeskService,
        {
          provide: 'REDIS_CLIENT',
          useValue: mockRedis,
        },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.listen(port);
  });

  afterAll(async () => {
    if (clientSocket) clientSocket.disconnect();
    if (targetSocket) targetSocket.disconnect();
    await app.close();
  });

  describe('desk:join', () => {
    it('应该成功加入房间', (done) => {
      clientSocket = io(`http://localhost:${port}/desk`, {
        query: { token: jwt.sign({ sub: 'user1' }, 'test-secret') },
      });

      clientSocket.on('connect', () => {
        clientSocket.emit('desk:join', {
          uuid: 'test-device-uuid',
          password: 'test-password',
        });
      });

      clientSocket.on('desk:joined', (data) => {
        expect(data.data.roomId).toBeDefined();
        expect(data.data.roomId).toBe('room_test-device-uuid');
        done();
      });
    });

    it('应该拒绝密码错误', (done) => {
      const badSocket = io(`http://localhost:${port}/desk`, {
        query: { token: jwt.sign({ sub: 'user2' }, 'test-secret') },
      });

      badSocket.on('connect', () => {
        badSocket.emit('desk:join', {
          uuid: 'test-device-uuid',
          password: 'wrong-password',
        });
      });

      badSocket.on('desk:joined', (data) => {
        expect(data.data.code).not.toBe(0);
        badSocket.disconnect();
        done();
      });
    });
  });

  describe('desk:update-status', () => {
    it('应该成功更新在线状态', (done) => {
      clientSocket.emit('desk:update-status', {
        uuid: 'test-device-uuid',
      });
      setTimeout(() => {
        expect(mockRedis.set).toHaveBeenCalled();
        done();
      }, 100);
    });
  });

  describe('desk:start-remote', () => {
    it('应该返回参数为空错误', (done) => {
      clientSocket.emit('desk:start-remote', {
        request_id: 'req1',
        controller_uuid: '',
        controller_password: '',
        target_uuid: '',
        target_password: '',
      });

      clientSocket.on('desk:start-remote-result', (data) => {
        if (data.data.code === 1) {
          expect(data.data.code).toBe(1);
          done();
        }
      });
    });
  });

  describe('desk:offer', () => {
    it('应该转发offer到目标设备', (done) => {
      targetSocket = io(`http://localhost:${port}/desk`, {
        query: { token: jwt.sign({ sub: 'user3' }, 'test-secret') },
      });

      targetSocket.on('connect', () => {
        targetSocket.on('desk:offer', (data) => {
          expect(data.data.sdp).toBe('test-sdp');
          expect(data.data.from_socket_id).toBeDefined();
          done();
        });

        clientSocket.emit('desk:offer', {
          request_id: 'req2',
          target_socket_id: targetSocket.id,
          sdp: 'test-sdp',
        });
      });
    });
  });

  describe('desk:answer', () => {
    it('应该转发answer到目标设备', (done) => {
      clientSocket.on('desk:answer', (data) => {
        expect(data.data.sdp).toBe('test-answer-sdp');
        done();
      });

      targetSocket.emit('desk:answer', {
        request_id: 'req3',
        target_socket_id: clientSocket.id,
        sdp: 'test-answer-sdp',
      });
    });
  });

  describe('desk:candidate', () => {
    it('应该转发candidate到目标设备', (done) => {
      clientSocket.on('desk:candidate', (data) => {
        expect(data.data.candidate).toEqual({ candidate: 'test-candidate' });
        done();
      });

      targetSocket.emit('desk:candidate', {
        request_id: 'req4',
        target_socket_id: clientSocket.id,
        candidate: { candidate: 'test-candidate' },
      });
    });
  });

  describe('desk:behavior', () => {
    it('应该转发行为到房间内设备', (done) => {
      targetSocket.on('desk:behavior', (data) => {
        expect(data.data.type).toBe('mouseMove');
        expect(data.data.x).toBe(100);
        expect(data.data.y).toBe(200);
        done();
      });

      clientSocket.emit('desk:behavior', {
        request_id: 'req5',
        type: 'mouseMove',
        x: 100,
        y: 200,
      });
    });
  });

  describe('desk:change-params', () => {
    it('应该转发参数变更到目标设备', (done) => {
      clientSocket.on('desk:change-params', (data) => {
        expect(data.data.max_bitrate).toBe(3000);
        expect(data.data.max_framerate).toBe(60);
        done();
      });

      targetSocket.emit('desk:change-params', {
        request_id: 'req6',
        target_socket_id: clientSocket.id,
        max_bitrate: 3000,
        max_framerate: 60,
        resolution: '1080p',
        video_hint: 'detailed',
        audio_hint: 'speech',
      });
    });
  });
});
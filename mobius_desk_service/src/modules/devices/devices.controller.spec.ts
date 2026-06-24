import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule } from '@nestjs/config';
import * as request from 'supertest';
import { DevicesController } from './devices.controller';
import { DevicesService } from './devices.service';
import { Device, DeviceSchema } from './schemas/device.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { TransformInterceptor } from '../../common/interceptors/transform.interceptor';
import { AllExceptionsFilter } from '../../common/filters/all-exceptions.filter';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';


import * as jwt from 'jsonwebtoken';

describe('DevicesController', () => {
  let app: INestApplication;
  let authToken: string;
  let deviceUuid: string;
  let devicePassword: string;

  const mockRedis = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
    exists: jest.fn(),
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
        MongooseModule.forFeature([
          { name: Device.name, schema: DeviceSchema },
          { name: User.name, schema: UserSchema },
        ]),
        JwtModule.register({ secret: 'test-secret', signOptions: { expiresIn: '1h' } }),
      ],
      controllers: [DevicesController],
      providers: [
        DevicesService,
        {
          provide: 'REDIS_CLIENT',
          useValue: mockRedis,
        },
        {
          provide: JwtAuthGuard,
          useValue: { canActivate: jest.fn().mockReturnValue(true) },
        },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    app.useGlobalInterceptors(new TransformInterceptor());
    app.useGlobalFilters(new AllExceptionsFilter());
    await app.init();

    authToken = jwt.sign(
      { sub: 'test-user-id', username: 'testuser' },
      'test-secret',
    );
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /api/v1/devices', () => {
    it('应该成功注册设备（无关联用户）', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices')
        .send({})
        .expect(201)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.uuid).toBeDefined();
          expect(res.body.data.password).toBeDefined();
          expect(res.body.data.id).toBeDefined();
          deviceUuid = res.body.data.uuid;
          devicePassword = res.body.data.password;
        });
    });

    it('应该成功注册设备（关联用户名）', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices')
        .send({ username: 'testuser' })
        .expect(201)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.uuid).toBeDefined();
          expect(res.body.data.password).toBeDefined();
        });
    });
  });

  describe('POST /api/v1/devices/login', () => {
    it('应该成功登录设备', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices/login')
        .send({ uuid: deviceUuid, password: devicePassword })
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.uuid).toBe(deviceUuid);
        });
    });

    it('应该拒绝错误密码', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices/login')
        .send({ uuid: deviceUuid, password: 'wrongpassword' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝不存在的设备UUID', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices/login')
        .send({ uuid: 'nonexistent-uuid', password: 'somepassword' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝缺少UUID', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices/login')
        .send({ password: devicePassword })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝缺少密码', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices/login')
        .send({ uuid: deviceUuid })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });
  });

  describe('POST /api/v1/devices/verify', () => {
    it('应该成功验证设备密码（有效）', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices/verify')
        .send({ uuid: deviceUuid, password: devicePassword })
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.valid).toBe(true);
        });
    });

    it('应该返回无效验证（错误密码）', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices/verify')
        .send({ uuid: deviceUuid, password: 'wrongpassword' })
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.valid).toBe(false);
        });
    });

    it('应该返回无效验证（不存在的UUID）', () => {
      return request(app.getHttpServer())
        .post('/api/v1/devices/verify')
        .send({ uuid: 'nonexistent-uuid', password: 'somepassword' })
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.valid).toBe(false);
        });
    });
  });

  describe('PUT /api/v1/devices/:uuid/password', () => {
    it('应该成功更新设备密码', () => {
      return request(app.getHttpServer())
        .put(`/api/v1/devices/${deviceUuid}/password`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ password: 'newpassword' })
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
        });
    });

    it('应该拒绝未认证请求', () => {
      return request(app.getHttpServer())
        .put(`/api/v1/devices/${deviceUuid}/password`)
        .send({ password: 'newpassword' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝不存在的设备UUID', () => {
      return request(app.getHttpServer())
        .put('/api/v1/devices/nonexistent-uuid/password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ password: 'newpassword' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });
  });

  describe('GET /api/v1/devices/:uuid/online', () => {
    it('应该返回设备离线状态', () => {
      mockRedis.exists.mockResolvedValueOnce(0);
      return request(app.getHttpServer())
        .get(`/api/v1/devices/${deviceUuid}/online`)
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.online).toBe(false);
        });
    });

    it('应该返回设备在线状态', () => {
      mockRedis.exists.mockResolvedValueOnce(1);
      return request(app.getHttpServer())
        .get(`/api/v1/devices/${deviceUuid}/online`)
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.online).toBe(true);
        });
    });
  });
});
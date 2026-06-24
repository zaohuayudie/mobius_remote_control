import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule } from '@nestjs/config';
import * as request from 'supertest';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { User, UserSchema } from '../users/schemas/user.schema';
import { TransformInterceptor } from '../../common/interceptors/transform.interceptor';
import { AllExceptionsFilter } from '../../common/filters/all-exceptions.filter';

describe('AuthController', () => {
  let app: INestApplication;
  let authToken: string;
  let userId: string;

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
              jwt: {
                secret: 'test-secret',
                expiresIn: '1h',
              },
            }),
          ],
        }),
        MongooseModule.forRoot(process.env.MONGO_TEST_URI || 'mongodb://localhost:27017/mobius_desk_test'),
        MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
        JwtModule.register({
          secret: 'test-secret',
          signOptions: { expiresIn: '1h' },
        }),
      ],
      controllers: [AuthController],
      providers: [AuthService],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    app.useGlobalInterceptors(new TransformInterceptor());
    app.useGlobalFilters(new AllExceptionsFilter());
    await app.init();
  });

  afterAll(async () => {
    const userModel = app.get('UserModel');
    if (userModel) {
      await userModel.deleteMany({});
    }
    await app.close();
  });

  describe('POST /api/v1/auth/register', () => {
    it('应该成功注册新用户', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send({ username: 'testuser', password: 'test123456' })
        .expect(201)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.username).toBe('testuser');
          expect(res.body.data.id).toBeDefined();
          userId = res.body.data.id;
        });
    });

    it('应该拒绝重复用户名注册', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send({ username: 'testuser', password: 'test123456' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝用户名过短（少于3字符）', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send({ username: 'ab', password: 'test123456' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝密码过短（少于6字符）', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send({ username: 'newuser', password: '12345' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝缺少必填字段', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send({ username: 'newuser' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝用户名超过64字符', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send({ username: 'a'.repeat(65), password: 'test123456' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝密码超过32字符', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send({ username: 'newuser2', password: 'a'.repeat(33) })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });
  });

  describe('POST /api/v1/auth/login', () => {
    it('应该成功登录', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ username: 'testuser', password: 'test123456' })
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.token).toBeDefined();
          expect(res.body.data.user.username).toBe('testuser');
          authToken = res.body.data.token;
        });
    });

    it('应该拒绝错误密码', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ username: 'testuser', password: 'wrongpassword' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝不存在的用户', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ username: 'nonexistent', password: 'test123456' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝缺少用户名', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ password: 'test123456' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝缺少密码', () => {
      return request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ username: 'testuser' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });
  });
});
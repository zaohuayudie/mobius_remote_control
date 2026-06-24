import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule } from '@nestjs/config';
import * as request from 'supertest';
import * as jwt from 'jsonwebtoken';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { User, UserSchema } from './schemas/user.schema';
import { TransformInterceptor } from '../../common/interceptors/transform.interceptor';
import { AllExceptionsFilter } from '../../common/filters/all-exceptions.filter';

describe('UsersController', () => {
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
              jwt: { secret: 'test-secret', expiresIn: '1h' },
            }),
          ],
        }),
        MongooseModule.forRoot(process.env.MONGO_TEST_URI || 'mongodb://localhost:27017/mobius_desk_test'),
        MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
        JwtModule.register({ secret: 'test-secret', signOptions: { expiresIn: '1h' } }),
      ],
      controllers: [UsersController],
      providers: [UsersService],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    app.useGlobalInterceptors(new TransformInterceptor());
    app.useGlobalFilters(new AllExceptionsFilter());
    await app.init();

    const jwtService = app.get('JwtService');
    const userModel = app.get('UserModel');

    const user = await userModel.create({
      username: 'testuser',
      password: '$2b$10$hashedpassword',
    });
    userId = user._id.toString();

    authToken = jwt.sign(
      { sub: userId, username: 'testuser' },
      'test-secret',
    );
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /api/v1/users/me', () => {
    it('应该返回当前用户信息', () => {
      return request(app.getHttpServer())
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.username).toBe('testuser');
        });
    });

    it('应该拒绝未认证请求', () => {
      return request(app.getHttpServer())
        .get('/api/v1/users/me')
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });
  });

  describe('PUT /api/v1/users/me', () => {
    it('应该成功更新密码', () => {
      return request(app.getHttpServer())
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ password: 'newpassword123' })
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
        });
    });

    it('应该拒绝未认证请求', () => {
      return request(app.getHttpServer())
        .put('/api/v1/users/me')
        .send({ password: 'newpassword123' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该拒绝密码过短（少于6字符）', () => {
      return request(app.getHttpServer())
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ password: '12345' })
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });
  });

  describe('GET /api/v1/users/:id', () => {
    it('应该返回指定用户信息', () => {
      return request(app.getHttpServer())
        .get(`/api/v1/users/${userId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.username).toBe('testuser');
        });
    });

    it('应该返回不存在用户', () => {
      return request(app.getHttpServer())
        .get('/api/v1/users/000000000000000000000000')
        .set('Authorization', `Bearer ${authToken}`)
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });
  });
});
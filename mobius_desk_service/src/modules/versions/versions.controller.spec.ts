import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';
import * as request from 'supertest';
import { VersionsController } from './versions.controller';
import { VersionsService } from './versions.service';
import { Version, VersionSchema } from './schemas/version.schema';
import { TransformInterceptor } from '../../common/interceptors/transform.interceptor';
import { AllExceptionsFilter } from '../../common/filters/all-exceptions.filter';

describe('VersionsController', () => {
  let app: INestApplication;

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
        MongooseModule.forFeature([{ name: Version.name, schema: VersionSchema }]),
      ],
      controllers: [VersionsController],
      providers: [VersionsService],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    app.useGlobalInterceptors(new TransformInterceptor());
    app.useGlobalFilters(new AllExceptionsFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /api/v1/versions/check', () => {
    it('应该返回无更新（无版本记录）', () => {
      return request(app.getHttpServer())
        .get('/api/v1/versions/check?platform=win&version=1.0.0')
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.hasUpdate).toBe(false);
        });
    });

    it('应该拒绝无效平台参数', () => {
      return request(app.getHttpServer())
        .get('/api/v1/versions/check?platform=invalid&version=1.0.0')
        .expect((res) => {
          expect(res.body.code).not.toBe(0);
        });
    });

    it('应该返回有更新（版本号较低）', async () => {
      const versionModel = app.get('VersionModel');
      await versionModel.create({
        version: '2.0.0',
        force: 0,
        content: '大版本更新',
        download_win: 'https://example.com/download',
      });

      return request(app.getHttpServer())
        .get('/api/v1/versions/check?platform=win&version=1.0.0')
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.hasUpdate).toBe(true);
          expect(res.body.data.version).toBe('2.0.0');
          expect(res.body.data.downloadUrl).toBe('https://example.com/download');
        });
    });

    it('应该返回无更新（版本号相同或更高）', () => {
      return request(app.getHttpServer())
        .get('/api/v1/versions/check?platform=win&version=2.0.0')
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.hasUpdate).toBe(false);
        });
    });

    it('应该返回强制更新标记', async () => {
      const versionModel = app.get('VersionModel');
      await versionModel.create({
        version: '3.0.0',
        force: 1,
        content: '强制更新',
        download_mac: 'https://example.com/mac',
      });

      return request(app.getHttpServer())
        .get('/api/v1/versions/check?platform=mac&version=2.0.0')
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.hasUpdate).toBe(true);
          expect(res.body.data.force).toBe(true);
        });
    });

    it('应该返回对应平台的下载链接', () => {
      return request(app.getHttpServer())
        .get('/api/v1/versions/check?platform=mac&version=1.0.0')
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
          expect(res.body.data.downloadUrl).toBeDefined();
        });
    });

    it('应该返回null下载链接（平台无对应链接）', () => {
      return request(app.getHttpServer())
        .get('/api/v1/versions/check?platform=android&version=1.0.0')
        .expect(200)
        .expect((res) => {
          expect(res.body.code).toBe(0);
        });
    });
  });
});
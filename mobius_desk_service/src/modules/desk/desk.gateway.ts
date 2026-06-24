import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { DeskService } from './desk.service';
import { Inject, Logger } from '@nestjs/common';
import Redis from 'ioredis';

interface MobiusSocket extends Socket {
  deviceUuid?: string;
  user?: any;
}

@WebSocketGateway({
  namespace: '/desk',
  cors: {
    origin: '*',
  },
})
export class DeskGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private logger = new Logger('WS:Desk');

  constructor(
    private readonly deskService: DeskService,
    @Inject('REDIS_CLIENT') private redis: Redis,
  ) {}

  private tag(client: MobiusSocket): string {
    return client.deviceUuid || client.id.slice(0, 8);
  }

  async handleConnection(client: MobiusSocket) {
    const token = client.handshake.query.token as string;
    const deviceUuid = client.handshake.query.device_uuid as string;
    const devicePassword = client.handshake.query.device_password as string;

    if (token) {
      try {
        const payload = await this.deskService.verifyToken(token);
        client.user = payload;
        this.logger.log(`[${client.id.slice(0, 8)}] Connected (token auth)`);
      } catch {
        this.logger.warn(`[${client.id.slice(0, 8)}] Connection rejected: invalid token`);
        client.disconnect();
        return;
      }
    } else if (deviceUuid && devicePassword) {
      const valid = await this.deskService.verifyDevice(
        deviceUuid,
        devicePassword,
      );
      if (!valid) {
        this.logger.warn(`[${deviceUuid}] Connection rejected: invalid device credentials`);
        client.disconnect();
        return;
      }
      client.deviceUuid = deviceUuid;
      this.logger.log(`[${deviceUuid}] Connected (device auth)`);
    } else {
      this.logger.warn(`[${client.id.slice(0, 8)}] Connection rejected: no credentials`);
      client.disconnect();
      return;
    }
  }

  async handleDisconnect(client: MobiusSocket) {
    const deviceUuid = client.deviceUuid;
    this.logger.log(`[${this.tag(client)}] Disconnected`);
    if (deviceUuid) {
      await this.redis.del(`mobius:device:uuid:${deviceUuid}`);
      await this.redis.del(`mobius:device:socket:${client.id}`);
      const roomId = await this.redis.get(`mobius:device:roomid:${deviceUuid}`);
      if (roomId) {
        await client.leave(roomId);
      }
    }
  }

  @SubscribeMessage('desk:join')
  async handleJoin(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody() data: { uuid: string; password: string },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:join data=${JSON.stringify(data)}`);

    const valid = await this.deskService.verifyDevice(data.uuid, data.password);
    if (!valid) {
      this.logger.warn(`[${this.tag(client)}] desk:join rejected: password error`);
      client.emit('desk:joined', {
        event: 'desk:joined',
        request_id: '',
        time: Date.now(),
        data: { code: 1, message: '密码错误' },
      });
      return;
    }

    const roomId = `room_${data.uuid}`;
    await client.join(roomId);
    client.deviceUuid = data.uuid;

    await this.redis.set(
      `mobius:device:uuid:${data.uuid}`,
      client.id,
      'EX',
      60,
    );
    await this.redis.set(
      `mobius:device:socket:${client.id}`,
      data.uuid,
      'EX',
      60,
    );
    await this.redis.set(`mobius:device:roomid:${data.uuid}`, roomId, 'EX', 60);
    await this.redis.hset(
      `mobius:device:room:${roomId}`,
      data.uuid,
      client.id,
    );
    await this.redis.expire(`mobius:device:room:${roomId}`, 60);

    this.logger.log(`[${data.uuid}] desk:joined room=${roomId}`);

    client.emit('desk:joined', {
      event: 'desk:joined',
      request_id: '',
      time: Date.now(),
      data: { roomId },
    });
  }

  @SubscribeMessage('desk:update-status')
  async handleUpdateStatus(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody() data: { uuid: string },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:update-status data=${JSON.stringify(data)}`);

    await this.redis.set(
      `mobius:device:uuid:${data.uuid}`,
      client.id,
      'EX',
      60,
    );
    await this.redis.set(
      `mobius:device:socket:${client.id}`,
      data.uuid,
      'EX',
      60,
    );
    const roomId = await this.redis.get(`mobius:device:roomid:${data.uuid}`);
    if (roomId) {
      await this.redis.expire(`mobius:device:roomid:${data.uuid}`, 60);
      await this.redis.expire(`mobius:device:room:${roomId}`, 60);
    }
  }

  @SubscribeMessage('desk:start-remote')
  async handleStartRemote(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody()
    data: {
      request_id: string;
      controller_uuid: string;

      target_uuid: string;
      target_password: string;
      max_bitrate?: number;
      max_framerate?: number;
      resolution?: string;
      video_hint?: string;
      audio_hint?: string;
    },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:start-remote data=${JSON.stringify(data)}`);

    const result = await this.deskService.handleStartRemote(client, data);
    const targetSocketId = await this.redis.get(
      `mobius:device:uuid:${data.target_uuid}`,
    );

    this.logger.log(`[${this.tag(client)}] desk:start-remote-result code=${result.code} message=${result.message}`);

    const responseData = {
      event: 'desk:start-remote-result',
      request_id: data.request_id || '',
      time: Date.now(),
      data: result,
    };

    client.emit('desk:start-remote-result', responseData);
    if (targetSocketId && result.code === 0) {
      this.server.to(targetSocketId).emit('desk:start-remote-result', responseData);
    }
  }

  @SubscribeMessage('desk:accept-remote')
  async handleAcceptRemote(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody()
    data: { request_id: string; target_socket_id: string },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:accept-remote data=${JSON.stringify(data)}`);

    const responseData = {
      event: 'desk:accept-remote',
      request_id: data.request_id || '',
      time: Date.now(),
      data: {
        from_socket_id: client.id,
        from_uuid: client.deviceUuid,
      },
    };

    client.emit('desk:accept-remote', responseData);
    if (data.target_socket_id) {
      this.server.to(data.target_socket_id).emit('desk:accept-remote', responseData);
    }
  }

  @SubscribeMessage('desk:reject-remote')
  async handleRejectRemote(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody()
    data: { request_id: string; target_socket_id: string },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:reject-remote data=${JSON.stringify(data)}`);

    const responseData = {
      event: 'desk:reject-remote',
      request_id: data.request_id || '',
      time: Date.now(),
      data: {
        from_socket_id: client.id,
        from_uuid: client.deviceUuid,
      },
    };

    client.emit('desk:reject-remote', responseData);
    if (data.target_socket_id) {
      this.server.to(data.target_socket_id).emit('desk:reject-remote', responseData);
    }
  }

  @SubscribeMessage('desk:stop-remote')
  async handleStopRemote(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody()
    data: {
      request_id: string;
      target_socket_id: string;
      reason?: string;
    },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:stop-remote data=${JSON.stringify(data)}`);

    const responseData = {
      event: 'desk:stop-remote-result',
      request_id: data.request_id || '',
      time: Date.now(),
      data: {
        from_socket_id: client.id,
        reason: data.reason || 'normal',
      },
    };

    client.emit('desk:stop-remote-result', responseData);
    if (data.target_socket_id) {
      this.server.to(data.target_socket_id).emit('desk:stop-remote-result', responseData);
    }
  }

  @SubscribeMessage('desk:offer')
  async handleOffer(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody() data: { request_id: string; target_socket_id: string; sdp: string },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:offer data=${JSON.stringify({ request_id: data.request_id, target_socket_id: data.target_socket_id })}`);

    this.server.to(data.target_socket_id).emit('desk:offer', {
      event: 'desk:offer',
      request_id: data.request_id || '',
      time: Date.now(),
      data: {
        from_socket_id: client.id,
        sdp: data.sdp,
      },
    });
  }

  @SubscribeMessage('desk:answer')
  async handleAnswer(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody() data: { request_id: string; target_socket_id: string; sdp: string },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:answer data=${JSON.stringify({ request_id: data.request_id, target_socket_id: data.target_socket_id })}`);

    this.server.to(data.target_socket_id).emit('desk:answer', {
      event: 'desk:answer',
      request_id: data.request_id || '',
      time: Date.now(),
      data: {
        from_socket_id: client.id,
        sdp: data.sdp,
      },
    });
  }

  @SubscribeMessage('desk:candidate')
  async handleCandidate(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody() data: { request_id: string; target_socket_id: string; candidate: any },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:candidate data=${JSON.stringify({ request_id: data.request_id, target_socket_id: data.target_socket_id })}`);

    this.server.to(data.target_socket_id).emit('desk:candidate', {
      event: 'desk:candidate',
      request_id: data.request_id || '',
      time: Date.now(),
      data: {
        from_socket_id: client.id,
        candidate: data.candidate,
      },
    });
  }

  @SubscribeMessage('desk:behavior')
  async handleBehavior(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody()
    data: {
      request_id: string;
      target_socket_id: string;
      type: string;
      x?: number;
      y?: number;
      amount?: number;
      keyboard_type?: string;
    },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:behavior type=${data.type} target=${data.target_socket_id}`);

    if (data.target_socket_id) {
      this.server.to(data.target_socket_id).emit('desk:behavior', {
        event: 'desk:behavior',
        request_id: data.request_id || '',
        time: Date.now(),
        data: {
          from_socket_id: client.id,
          type: data.type,
          x: data.x,
          y: data.y,
          amount: data.amount,
          keyboard_type: data.keyboard_type,
        },
      });
    }
  }

  @SubscribeMessage('desk:change-params')
  async handleChangeParams(
    @ConnectedSocket() client: MobiusSocket,
    @MessageBody()
    data: {
      request_id: string;
      target_socket_id: string;
      max_bitrate?: number;
      max_framerate?: number;
      resolution?: string;
      video_hint?: string;
      audio_hint?: string;
    },
  ) {
    this.logger.log(`[${this.tag(client)}] desk:change-params data=${JSON.stringify(data)}`);

    this.server.to(data.target_socket_id).emit('desk:change-params', {
      event: 'desk:change-params',
      request_id: data.request_id || '',
      time: Date.now(),
      data: {
        from_socket_id: client.id,
        max_bitrate: data.max_bitrate,
        max_framerate: data.max_framerate,
        resolution: data.resolution,
        video_hint: data.video_hint,
        audio_hint: data.audio_hint,
      },
    });
  }
}

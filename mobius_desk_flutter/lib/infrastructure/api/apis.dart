import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:mobius_desk_flutter/domain/models/device.dart';
import 'package:mobius_desk_flutter/domain/models/user.dart';
import 'package:mobius_desk_flutter/domain/models/app_version.dart';
import 'package:mobius_desk_flutter/domain/repositories/repositories.dart';
import 'package:mobius_desk_flutter/infrastructure/api/api_client.dart';

class AuthApi implements AuthRepository {
  final ApiClient _client;
  AuthApi(this._client);

  @override
  Future<User> register({
    required String username,
    required String password,
  }) async {
    final res = await _client.post('/auth/register', data: {
      'username': username,
      'password': password,
    });
    return User.fromJson(res.data['data']);
  }

  @override
  Future<({String token, User user})> login({
    required String username,
    required String password,
  }) async {
    final res = await _client.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    final d = res.data['data'];
    _client.setToken(d['token']);
    return (token: d['token'] as String, user: User.fromJson(d['user']));
  }
}

class DeviceApi implements DeviceRepository {
  final ApiClient _client;
  DeviceApi(this._client);

  @override
  Future<Device> create({String? username}) async {
    final res = await _client.post('/devices', data: {
      if (username != null) 'username': username,
    });
    return Device.fromJson(res.data['data']);
  }

  @override
  Future<Device> login({
    required String uuid,
    required String password,
  }) async {
    final res = await _client.post('/devices/login', data: {
      'uuid': uuid,
      'password': password,
    });
    return Device.fromJson(res.data['data']);
  }

  @override
  Future<bool> verify({
    required String uuid,
    required String password,
  }) async {
    final res = await _client.post('/devices/verify', data: {
      'uuid': uuid,
      'password': password,
    });
    return res.data['data']['valid'] == true;
  }

  @override
  Future<void> updatePassword({
    required String uuid,
    required String password,
  }) async {
    await _client.put('/devices/$uuid/password', data: {
      'password': password,
    });
  }

  @override
  Future<bool> checkOnline({required String uuid}) async {
    final res = await _client.get('/devices/$uuid/online');
    return res.data['data']['online'] == true;
  }

  @override
  Future<List<Device>> list() async {
    final res = await _client.get('/devices');
    dynamic rawData = res.data;
    if (rawData is String) {
      rawData = jsonDecode(rawData);
    }
    final data = rawData['data'];
    if (data == null || data is! List) return [];
    return data.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class VersionApi implements VersionRepository {
  final ApiClient _client;
  VersionApi(this._client);

  @override
  Future<AppVersion?> checkUpdate({
    required String platform,
    required String currentVersion,
  }) async {
    try {
      final res = await _client.get(
        '/versions/check',
        queryParameters: {
          'platform': platform,
          'version': currentVersion,
        },
      );
      final d = res.data['data'];
      if (d['hasUpdate'] == true) {
        return AppVersion.fromJson(d);
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
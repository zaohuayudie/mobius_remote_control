import 'package:mobius_desk_flutter/domain/models/device.dart';
import 'package:mobius_desk_flutter/domain/models/user.dart';
import 'package:mobius_desk_flutter/domain/models/app_version.dart';

abstract class AuthRepository {
  Future<User> register({required String username, required String password});
  Future<({String token, User user})> login({
    required String username,
    required String password,
  });
}

abstract class DeviceRepository {
  Future<Device> create({String? username});
  Future<Device> login({required String uuid, required String password});
  Future<bool> verify({required String uuid, required String password});
  Future<void> updatePassword({required String uuid, required String password});
  Future<bool> checkOnline({required String uuid});
  Future<List<Device>> list();
}

abstract class VersionRepository {
  Future<AppVersion?> checkUpdate({
    required String platform,
    required String currentVersion,
  });
}
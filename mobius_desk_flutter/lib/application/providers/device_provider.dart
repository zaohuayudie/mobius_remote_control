import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobius_desk_flutter/domain/models/device.dart';
import 'package:mobius_desk_flutter/infrastructure/api/apis.dart';
import 'package:mobius_desk_flutter/infrastructure/storage/local_storage.dart';
import 'package:mobius_desk_flutter/application/providers/infrastructure_providers.dart';

class DeviceState {
  final String? uuid;
  final String? password;
  final bool isLoggedIn;

  const DeviceState({
    this.uuid,
    this.password,
    this.isLoggedIn = false,
  });

  DeviceState copyWith({
    String? uuid,
    String? password,
    bool? isLoggedIn,
  }) =>
      DeviceState(
        uuid: uuid ?? this.uuid,
        password: password ?? this.password,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      );
}

class DeviceNotifier extends StateNotifier<DeviceState> {
  final DeviceApi _deviceApi;
  final LocalStorage _localStorage;

  DeviceNotifier(this._deviceApi, this._localStorage)
      : super(const DeviceState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final uuid = _localStorage.deviceUuid;
    final password = _localStorage.devicePassword;
    if (uuid != null && password != null) {
      state = state.copyWith(uuid: uuid, password: password, isLoggedIn: true);
    }
  }

  Future<void> register({String? username}) async {
    final device = await _deviceApi.create(username: username);
    await _localStorage.setDevice(device.uuid, device.password ?? '');
    state = state.copyWith(
      uuid: device.uuid,
      password: device.password,
      isLoggedIn: true,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    if (state.uuid == null) return;
    await _deviceApi.updatePassword(
      uuid: state.uuid!,
      password: newPassword,
    );
    await _localStorage.setDevice(state.uuid!, newPassword);
    state = state.copyWith(password: newPassword);
  }

  Future<bool> checkOnline(String uuid) async {
    return _deviceApi.checkOnline(uuid: uuid);
  }

  Future<bool> verifyDevice({required String uuid, required String password}) async {
    try {
      return await _deviceApi.verify(uuid: uuid, password: password);
    } catch (_) {
      return false;
    }
  }

  Future<List<Device>> listDevices() async {
    return _deviceApi.list();
  }
}

final deviceProvider =
    StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  final deviceApi = ref.watch(deviceApiProvider);
  final localStorageAsync = ref.watch(localStorageProvider);
  final localStorage = localStorageAsync.valueOrNull ?? LocalStorage.dummy();
  return DeviceNotifier(deviceApi, localStorage);
});
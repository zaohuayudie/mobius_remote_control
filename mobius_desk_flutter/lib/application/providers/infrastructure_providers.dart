import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobius_desk_flutter/infrastructure/api/api_client.dart';
import 'package:mobius_desk_flutter/infrastructure/api/apis.dart';
import 'package:mobius_desk_flutter/infrastructure/storage/local_storage.dart';
import 'package:mobius_desk_flutter/infrastructure/websocket/ws_client.dart';
import 'package:mobius_desk_flutter/infrastructure/webrtc/rtc_manager.dart';

final localStorageProvider = FutureProvider<LocalStorage>((ref) async {
  return LocalStorage.instance;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final localStorageAsync = ref.watch(localStorageProvider);
  final localStorage = localStorageAsync.valueOrNull;
  return ApiClient(baseUrl: localStorage?.apiUrl);
});

final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApi(client);
});

final deviceApiProvider = Provider<DeviceApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return DeviceApi(client);
});

final versionApiProvider = Provider<VersionApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return VersionApi(client);
});

final wsClientProvider = Provider<WsClient>((ref) => WsClient());

final rtcManagerProvider = Provider<RtcManager>((ref) => RtcManager());
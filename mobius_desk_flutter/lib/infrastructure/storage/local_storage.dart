import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobius_desk_flutter/core/constants.dart';
import 'package:mobius_desk_flutter/core/enums.dart';
import 'package:mobius_desk_flutter/domain/models/remote_params.dart';

class LocalStorage {
  static LocalStorage? _instance;
  SharedPreferences? _prefs;

  LocalStorage._();

  static LocalStorage dummy() => LocalStorage._();

  static Future<LocalStorage> get instance async {
    if (_instance != null) return _instance!;
    _instance = LocalStorage._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  String? get deviceUuid => _prefs?.getString(AppConstants.deviceUuidKey);
  String? get devicePassword =>
      _prefs?.getString(AppConstants.devicePasswordKey);
  String get wssUrl =>
      _prefs?.getString(AppConstants.settingsWssUrlKey) ??
      AppConstants.defaultWssUrl;
  String get apiUrl =>
      _prefs?.getString(AppConstants.settingsApiUrlKey) ??
      AppConstants.defaultApiUrl;
  String? get coturnUrl =>
      _prefs?.getString(AppConstants.settingsCoturnUrlKey);

  RemoteParams get remoteParams {
    final bitrate = _prefs?.getInt(AppConstants.paramsBitrateKey);
    final framerate = _prefs?.getInt(AppConstants.paramsFramerateKey);
    final resLabel = _prefs?.getString(AppConstants.paramsResolutionKey);
    final videoHintVal = _prefs?.getString(AppConstants.paramsVideoHintKey);
    final audioHintVal = _prefs?.getString(AppConstants.paramsAudioHintKey);

    return RemoteParams(
      maxBitrate: bitrate ?? 2000,
      maxFramerate: framerate ?? 60,
      resolution: Resolution.values.firstWhere(
        (r) => r.label == resLabel,
        orElse: () => Resolution.p1080,
      ),
      videoHint: VideoContentHint.values.firstWhere(
        (v) => v.value == videoHintVal,
        orElse: () => VideoContentHint.detailed,
      ),
      audioHint: AudioContentHint.values.firstWhere(
        (a) => a.value == audioHintVal,
        orElse: () => AudioContentHint.speech,
      ),
    );
  }

  Future<void> setDevice(String uuid, String password) async {
    await _prefs?.setString(AppConstants.deviceUuidKey, uuid);
    await _prefs?.setString(AppConstants.devicePasswordKey, password);
  }

  Future<void> setWssUrl(String url) async {
    await _prefs?.setString(AppConstants.settingsWssUrlKey, url);
  }

  Future<void> setApiUrl(String url) async {
    await _prefs?.setString(AppConstants.settingsApiUrlKey, url);
  }

  Future<void> setCoturnUrl(String url) async {
    await _prefs?.setString(AppConstants.settingsCoturnUrlKey, url);
  }

  Future<void> setRemoteParams(RemoteParams params) async {
    await _prefs?.setInt(AppConstants.paramsBitrateKey, params.maxBitrate);
    await _prefs?.setInt(AppConstants.paramsFramerateKey, params.maxFramerate);
    await _prefs?.setString(AppConstants.paramsResolutionKey, params.resolution.label);
    await _prefs?.setString(AppConstants.paramsVideoHintKey, params.videoHint.value);
    await _prefs?.setString(AppConstants.paramsAudioHintKey, params.audioHint.value);
  }

  Future<void> clearDevice() async {
    await _prefs?.remove(AppConstants.deviceUuidKey);
    await _prefs?.remove(AppConstants.devicePasswordKey);
  }
}

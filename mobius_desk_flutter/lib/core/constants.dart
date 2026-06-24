class AppConstants {
  static const String appName = 'MobiusDesk';
  static const String appNameLower = 'mobius_desk';
  static const String deviceUuidKey = 'mobius_device_uuid';
  static const String devicePasswordKey = 'mobius_device_password';
  static const String settingsWssUrlKey = 'mobius_settings_wss_url';
  static const String settingsApiUrlKey = 'mobius_settings_api_url';
  static const String settingsCoturnUrlKey = 'mobius_settings_coturn_url';
  static const String paramsBitrateKey = 'mobius_params_bitrate';
  static const String paramsFramerateKey = 'mobius_params_framerate';
  static const String paramsResolutionKey = 'mobius_params_resolution';
  static const String paramsVideoHintKey = 'mobius_params_video_hint';
  static const String paramsAudioHintKey = 'mobius_params_audio_hint';

  static const String defaultApiUrl = 'http://192.168.3.11:4200/api/v1';
  static const String defaultWssUrl = 'ws://192.168.3.11:4200/desk';

  static const int heartbeatIntervalSeconds = 10;
  static const int wsReconnectDelaySeconds = 3;

  static const int normalizedWidth = 1000;
  static const int normalizedHeight = 1000;
}
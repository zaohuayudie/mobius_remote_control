import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobius_desk_flutter/infrastructure/api/api_client.dart';
import 'package:mobius_desk_flutter/infrastructure/storage/local_storage.dart';
import 'package:mobius_desk_flutter/application/providers/infrastructure_providers.dart';

class SettingState {
  final String wssUrl;
  final String apiUrl;
  final String? coturnUrl;

  const SettingState({
    this.wssUrl = 'ws://192.168.3.11:4200/desk',
    this.apiUrl = 'http://192.168.3.11:4200/api/v1',
    this.coturnUrl,
  });

  SettingState copyWith({
    String? wssUrl,
    String? apiUrl,
    String? coturnUrl,
  }) =>
      SettingState(
        wssUrl: wssUrl ?? this.wssUrl,
        apiUrl: apiUrl ?? this.apiUrl,
        coturnUrl: coturnUrl ?? this.coturnUrl,
      );
}

class SettingNotifier extends StateNotifier<SettingState> {
  final LocalStorage _localStorage;
  final ApiClient _apiClient;

  SettingNotifier(this._localStorage, this._apiClient)
      : super(SettingState(
          wssUrl: _localStorage.wssUrl,
          apiUrl: _localStorage.apiUrl,
          coturnUrl: _localStorage.coturnUrl,
        ));

  Future<void> setWssUrl(String url) async {
    await _localStorage.setWssUrl(url);
    state = state.copyWith(wssUrl: url);
  }

  Future<void> setApiUrl(String url) async {
    await _localStorage.setApiUrl(url);
    _apiClient.updateBaseUrl(url);
    state = state.copyWith(apiUrl: url);
  }

  Future<void> setCoturnUrl(String url) async {
    await _localStorage.setCoturnUrl(url);
    state = state.copyWith(coturnUrl: url);
  }
}

final settingProvider =
    StateNotifierProvider<SettingNotifier, SettingState>((ref) {
  final localStorageAsync = ref.watch(localStorageProvider);
  final localStorage = localStorageAsync.valueOrNull ?? LocalStorage.dummy();
  final apiClient = ref.watch(apiClientProvider);
  return SettingNotifier(localStorage, apiClient);
});
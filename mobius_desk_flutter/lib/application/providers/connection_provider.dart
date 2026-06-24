import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobius_desk_flutter/core/constants.dart';
import 'package:mobius_desk_flutter/core/enums.dart';
import 'package:mobius_desk_flutter/domain/models/remote_params.dart';
import 'package:mobius_desk_flutter/infrastructure/platform/accessibility_channel.dart';
import 'package:mobius_desk_flutter/infrastructure/storage/local_storage.dart';
import 'package:mobius_desk_flutter/infrastructure/websocket/ws_client.dart';
import 'package:mobius_desk_flutter/infrastructure/webrtc/rtc_manager.dart';
import 'package:mobius_desk_flutter/application/providers/infrastructure_providers.dart';

class MobiusConnectionState {
  final bool wsConnected;
  final bool wsConnecting;
  final String? wsError;
  final bool remoteConnecting;
  final String? remoteError;
  final String? remoteDeviceUuid;
  final ConnectionMode mode;
  final RemoteParams params;
  final String? remoteSocketId;
  final int rtt;
  final double packetLoss;
  final String currentResolution;
  final int currentFramerate;
  final String? incomingControllerUuid;
  final String? incomingControllerSocketId;
  final bool remoteAccepted;
  final bool remoteRejected;

  const MobiusConnectionState({
    this.wsConnected = false,
    this.wsConnecting = false,
    this.wsError,
    this.remoteConnecting = false,
    this.remoteError,
    this.remoteDeviceUuid,
    this.mode = ConnectionMode.control,
    this.params = const RemoteParams(),
    this.remoteSocketId,
    this.rtt = 0,
    this.packetLoss = 0,
    this.currentResolution = '',
    this.currentFramerate = 0,
    this.incomingControllerUuid,
    this.incomingControllerSocketId,
    this.remoteAccepted = false,
    this.remoteRejected = false,
  });

  bool get hasIncomingRequest => incomingControllerUuid != null;

  MobiusConnectionState copyWith({
    bool? wsConnected,
    bool? wsConnecting,
    String? wsError,
    bool? remoteConnecting,
    String? remoteError,
    String? remoteDeviceUuid,
    ConnectionMode? mode,
    RemoteParams? params,
    String? remoteSocketId,
    int? rtt,
    double? packetLoss,
    String? currentResolution,
    int? currentFramerate,
    String? incomingControllerUuid,
    String? incomingControllerSocketId,
    bool? remoteAccepted,
    bool? remoteRejected,
  }) =>
      MobiusConnectionState(
        wsConnected: wsConnected ?? this.wsConnected,
        wsConnecting: wsConnecting ?? this.wsConnecting,
        wsError: wsError,
        remoteConnecting: remoteConnecting ?? this.remoteConnecting,
        remoteError: remoteError,
        remoteDeviceUuid: remoteDeviceUuid ?? this.remoteDeviceUuid,
        mode: mode ?? this.mode,
        params: params ?? this.params,
        remoteSocketId: remoteSocketId ?? this.remoteSocketId,
        rtt: rtt ?? this.rtt,
        packetLoss: packetLoss ?? this.packetLoss,
        currentResolution: currentResolution ?? this.currentResolution,
        currentFramerate: currentFramerate ?? this.currentFramerate,
        incomingControllerUuid: incomingControllerUuid,
        incomingControllerSocketId: incomingControllerSocketId,
        remoteAccepted: remoteAccepted ?? this.remoteAccepted,
        remoteRejected: remoteRejected ?? this.remoteRejected,
      );
}

class ConnectionNotifier extends StateNotifier<MobiusConnectionState> {
  final WsClient _wsClient;
  final RtcManager _rtcManager;
  final LocalStorage _localStorage;
  Timer? _heartbeatTimer;
  Timer? _connectTimeoutTimer;
  bool _everConnected = false;

  ConnectionNotifier(this._wsClient, this._rtcManager, this._localStorage)
      : super(MobiusConnectionState(params: _localStorage.remoteParams));

  WsClient get wsClient => _wsClient;
  RtcManager get rtcManager => _rtcManager;

  void connectWebSocket() {
    final wssUrl = _localStorage.wssUrl;
    final uuid = _localStorage.deviceUuid;
    final password = _localStorage.devicePassword;

    state = state.copyWith(wsConnecting: true, wsError: null);

    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (state.wsConnecting && !state.wsConnected) {
        state = state.copyWith(
          wsConnecting: false,
          wsError: '连接超时，请检查服务器地址',
        );
      }
    });

    _wsClient.setHandlers(
      onConnect: () {
        _everConnected = true;
        _connectTimeoutTimer?.cancel();
        state = state.copyWith(wsConnected: true, wsConnecting: false, wsError: null);
        if (uuid != null && password != null) {
          _joinRoom();
        }
      },
      onDisconnect: () {
        _connectTimeoutTimer?.cancel();
        state = state.copyWith(wsConnected: false, wsConnecting: false);
        _stopHeartbeat();
      },
      onError: (data) {
        _connectTimeoutTimer?.cancel();
        state = state.copyWith(
          wsConnected: false,
          wsConnecting: false,
          wsError: data?.toString() ?? '连接失败',
        );
      },
    );

    _wsClient.connect(
      wssUrl,
      deviceUuid: uuid,
      devicePassword: password,
    );

    _listenWsEvents();
  }

  void joinRoom() {
    _joinRoom();
  }

  void _joinRoom() {
    final uuid = _localStorage.deviceUuid;
    final password = _localStorage.devicePassword;
    if (uuid == null || password == null) return;

    _wsClient.emit(WsEventType.deskJoin, {
      'uuid': uuid,
      'password': password,
    });

    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: AppConstants.heartbeatIntervalSeconds),
      (_) {
        final uuid = _localStorage.deviceUuid;
        if (uuid != null) {
          _wsClient.emit(WsEventType.deskUpdateStatus, {'uuid': uuid});
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
  }

  void _listenWsEvents() {
    _wsClient.on(WsEventType.deskJoined, (data) {});

    _wsClient.on(WsEventType.deskStartRemoteResult, (data) {
      final d = data['data'] as Map<String, dynamic>?;
      if (d == null) return;
      final code = d['code'] as int?;
      final myUuid = _localStorage.deviceUuid;
      final controllerUuid = d['controller']?['uuid'] as String?;

      if (code == 0 && controllerUuid != null && controllerUuid != myUuid) {
        state = state.copyWith(
          incomingControllerUuid: controllerUuid,
          incomingControllerSocketId: d['controller']?['socket_id'] as String?,
        );
        return;
      }

      if (code == 0) {
        final target = d['target'] as Map<String, dynamic>?;
        state = state.copyWith(
          remoteSocketId: target?['socket_id'] as String?,
          remoteConnecting: false,
          remoteError: null,
        );
      } else {
        final msg = d['message'] as String? ?? '连接失败';
        state = state.copyWith(
          remoteConnecting: false,
          remoteError: msg,
        );
      }
    });

    _wsClient.on(WsEventType.deskAcceptRemote, (data) {
      if (state.mode == ConnectionMode.control) {
        _handleAcceptRemote();
      }
    });

    _wsClient.on(WsEventType.deskOffer, (data) {
      final d = data['data'] as Map<String, dynamic>?;
      if (d == null) return;
      _handleRemoteOffer(d);
    });

    _wsClient.on(WsEventType.deskAnswer, (data) {
      final d = data['data'] as Map<String, dynamic>?;
      if (d == null) return;
      _rtcManager.handleAnswer(d);
    });

    _wsClient.on(WsEventType.deskCandidate, (data) {
      final d = data['data'] as Map<String, dynamic>?;
      if (d == null) return;
      final candidate = d['candidate'] as Map<String, dynamic>?;
      if (candidate != null) {
        _rtcManager.addCandidate(candidate);
      }
    });

    _wsClient.on(WsEventType.deskBehavior, (data) {
      if (state.mode != ConnectionMode.view) return;
      final d = data['data'] as Map<String, dynamic>?;
      if (d == null) return;
      _handleBehavior(d);
    });

    _wsClient.on(WsEventType.deskChangeParams, (data) {});

    _wsClient.on(WsEventType.deskRejectRemote, (data) {
      if (state.mode != ConnectionMode.control) return;
      state = state.copyWith(
        remoteConnecting: false,
        remoteRejected: true,
        remoteError: '对方已拒绝',
      );
    });

    _wsClient.on(WsEventType.deskStopRemoteResult, (data) {
      _cleanupRemote();
    });
  }

  Future<void> _handleAcceptRemote() async {
    state = state.copyWith(remoteAccepted: true);
    try {
      await _rtcManager.createConnection(
        onCandidate: (candidate) {
          final targetSocketId = state.remoteSocketId;
          if (targetSocketId != null) {
            _wsClient.emit(WsEventType.deskCandidate, {
              'target_socket_id': targetSocketId,
              'candidate': candidate,
            });
          }
        },
      );

      await _rtcManager.addTransceivers();
      await _rtcManager.ensureDataChannel();

      await _rtcManager.createOfferAndSend((offer) {
        final targetSocketId = state.remoteSocketId;
        if (targetSocketId != null) {
          _wsClient.emit(WsEventType.deskOffer, {
            'target_socket_id': targetSocketId,
            'sdp': offer['sdp'],
            'type': offer['type'],
          });
        }
      });
    } catch (e) {
      state = state.copyWith(
        remoteConnecting: false,
        remoteError: 'WebRTC connection failed',
        remoteAccepted: false,
        remoteRejected: false,
      );
    }
  }

  Future<void> _handleRemoteOffer(Map<String, dynamic> offer) async {
    await _rtcManager.createConnection(
      onCandidate: (candidate) {
        _wsClient.emit(WsEventType.deskCandidate, {
          'target_socket_id': offer['from_socket_id'],
          'candidate': candidate,
        });
      },
    );

    try {
      final localStream = await Helper.openCamera({
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': 640,
            'maxWidth': 1280,
            'minHeight': 480,
            'maxHeight': 720,
          },
        },
      });
      await _rtcManager.setLocalStream(localStream);
      developer.log('Local camera stream added, tracks: ${localStream.getTracks().length}', name: 'ConnectionNotifier');
    } catch (e) {
      developer.log('Failed to get camera stream: $e', name: 'ConnectionNotifier');
    }

    await _rtcManager.handleOffer(offer);
    final answer = await _rtcManager.createAnswer();
    final fromSocketId = offer['from_socket_id'] as String?;
    if (fromSocketId != null) {
      _wsClient.emit(WsEventType.deskAnswer, {
        'target_socket_id': fromSocketId,
        'sdp': answer['sdp'],
        'type': answer['type'],
      });
    }
  }

  void _handleBehavior(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;

    final normalizedX = (data['x'] as num?)?.toDouble() ?? 0.0;
    final normalizedY = (data['y'] as num?)?.toDouble() ?? 0.0;
    final amount = (data['amount'] as num?)?.toInt() ?? 3;

    final view = ui.PlatformDispatcher.instance.views.first;
    final screenW = view.physicalSize.width / view.devicePixelRatio;
    final screenH = view.physicalSize.height / view.devicePixelRatio;

    final x = (normalizedX / AppConstants.normalizedWidth) * screenW;
    final y = (normalizedY / AppConstants.normalizedHeight) * screenH;

    developer.log('Behavior: type=$type x=$x y=$y (raw=$normalizedX,$normalizedY screen=${screenW}x${screenH})', name: 'ConnectionNotifier');

    switch (type) {
      case 'mouseMove':
        AccessibilityChannel.performMove(x, y);
        break;
      case 'leftClick':
        AccessibilityChannel.performClick(x, y);
        break;
      case 'rightClick':
        AccessibilityChannel.performLongClick(x, y);
        break;
      case 'doubleClick':
        AccessibilityChannel.performClick(x, y);
        Future.delayed(const Duration(milliseconds: 100), () {
          AccessibilityChannel.performClick(x, y);
        });
        break;
      case 'mouseDrag':
        AccessibilityChannel.performSwipe(x, y, x, y, 300);
        break;
      case 'scrollUp':
        AccessibilityChannel.performScroll(x, y, 0, amount * 50.0);
        break;
      case 'scrollDown':
        AccessibilityChannel.performScroll(x, y, 0, -amount * 50.0);
        break;
      case 'scrollLeft':
        AccessibilityChannel.performScroll(x, y, amount * 50.0, 0);
        break;
      case 'scrollRight':
        AccessibilityChannel.performScroll(x, y, -amount * 50.0, 0);
        break;
      case 'pressButtonLeft':
        break;
      case 'releaseButtonLeft':
        break;
      case 'keyboardType':
        break;
      case 'keyboardPressKey':
        break;
      case 'keyboardReleaseKey':
        break;
      default:
        developer.log('Unknown behavior type: $type', name: 'ConnectionNotifier');
    }
  }

  void acceptIncoming() {
    final controllerSocketId = state.incomingControllerSocketId;
    final controllerUuid = state.incomingControllerUuid;
    if (controllerSocketId == null || controllerUuid == null) return;

    _wsClient.emit(WsEventType.deskAcceptRemote, {
      'target_socket_id': controllerSocketId,
    });

    state = state.copyWith(
      remoteDeviceUuid: controllerUuid,
      remoteSocketId: controllerSocketId,
      mode: ConnectionMode.view,
      incomingControllerUuid: null,
      incomingControllerSocketId: null,
    );
  }

  void rejectIncoming() {
    final controllerSocketId = state.incomingControllerSocketId;
    if (controllerSocketId != null) {
      _wsClient.emit(WsEventType.deskStopRemote, {
        'target_socket_id': controllerSocketId,
        'reason': 'rejected',
      });
    }
    state = state.copyWith(
      incomingControllerUuid: null,
      incomingControllerSocketId: null,
    );
  }

  void startRemote({
    required String targetUuid,
    required String targetPassword,
  }) {
    final uuid = _localStorage.deviceUuid;
    if (uuid == null) return;

    state = state.copyWith(
      remoteDeviceUuid: targetUuid,
      remoteConnecting: true,
      remoteError: null,
      mode: ConnectionMode.control,
    );

    _wsClient.emit(WsEventType.deskStartRemote, {
      'controller_uuid': uuid,
      'target_uuid': targetUuid,
      'target_password': targetPassword,
      ...state.params.toWsJson(),
    });
  }

  void sendBehavior(DeskBehaviorType type, {
    double? x,
    double? y,
    int? amount,
    String? keyboardType,
  }) {
    if (state.mode == ConnectionMode.view) return;
    final targetSocketId = state.remoteSocketId;
    if (targetSocketId == null) return;
    _wsClient.emit(WsEventType.deskBehavior, {
      'target_socket_id': targetSocketId,
      'type': type.value,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (amount != null) 'amount': amount,
      if (keyboardType != null) 'keyboard_type': keyboardType,
    });
  }

  void changeParams(RemoteParams params) {
    state = state.copyWith(params: params);
    _localStorage.setRemoteParams(params);
    final targetSocketId = state.remoteSocketId;
    if (targetSocketId == null) return;
    _wsClient.emit(WsEventType.deskChangeParams, {
      'target_socket_id': targetSocketId,
      ...params.toWsJson(),
    });
  }

  void setMode(ConnectionMode mode) {
    state = state.copyWith(mode: mode);
  }

  void resetRemoteState() {
    state = state.copyWith(
      remoteConnecting: false,
      remoteError: null,
      remoteAccepted: false,
      remoteRejected: false,
    );
  }

  void _cleanupRemote() {
    _rtcManager.dispose();
    _startHeartbeat();
    state = state.copyWith(
      remoteDeviceUuid: null,
      remoteSocketId: null,
      remoteConnecting: false,
      remoteError: null,
      rtt: 0,
      packetLoss: 0,
      currentResolution: '',
      currentFramerate: 0,
      incomingControllerUuid: null,
      incomingControllerSocketId: null,
    );
  }

  void stopRemote() {
    final targetSocketId = state.remoteSocketId;
    _cleanupRemote();
    if (targetSocketId != null) {
      _wsClient.emit(WsEventType.deskStopRemote, {
        'target_socket_id': targetSocketId,
        'reason': 'normal',
      });
    }
  }

  void disconnect() {
    _everConnected = false;
    _stopHeartbeat();
    _wsClient.disconnect();
    _rtcManager.dispose();
    state = const MobiusConnectionState();
  }
}

final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, MobiusConnectionState>((ref) {
  final wsClient = ref.watch(wsClientProvider);
  final rtcManager = ref.watch(rtcManagerProvider);
  final localStorageAsync = ref.watch(localStorageProvider);
  final localStorage = localStorageAsync.valueOrNull ?? LocalStorage.dummy();
  return ConnectionNotifier(wsClient, rtcManager, localStorage);
});

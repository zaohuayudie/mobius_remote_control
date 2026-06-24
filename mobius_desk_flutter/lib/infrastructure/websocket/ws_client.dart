import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobius_desk_flutter/core/constants.dart';
import 'package:mobius_desk_flutter/core/enums.dart';

class WsClient {
  io.Socket? _socket;
  String? _currentWssUrl;
  String? _deviceUuid;
  String? _devicePassword;
  final Map<String, Function> _handlers = {};
  final Map<String, Function> _eventHandlers = {};
  bool _eventsAttached = false;
  bool _autoReconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  static const int _maxReconnectAttempts = 20;

  String? get socketId => _socket?.id;
  bool get isConnected => _socket?.connected ?? false;

  void connect(String wssUrl, {String? deviceUuid, String? devicePassword}) {
    if (_socket?.connected == true && _currentWssUrl == wssUrl) return;
    _cancelReconnect();
    disconnect();
    _currentWssUrl = wssUrl;
    _deviceUuid = deviceUuid;
    _devicePassword = devicePassword;
    _autoReconnect = true;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    developer.log('WS connecting to $_currentWssUrl, uuid=$_deviceUuid', name: 'WsClient');

    final opts = io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery({
      if (_deviceUuid != null) 'device_uuid': _deviceUuid,
      if (_devicePassword != null) 'device_password': _devicePassword,
    }).build();

    _socket = io.io(_currentWssUrl, opts);

    _socket!.onConnect((_) {
      developer.log('WS connected, socketId=${_socket?.id}', name: 'WsClient');
      _reconnectAttempts = 0;
      _cancelReconnect();
      _reattachEventListeners();
      _handlers['onConnect']?.call();
    });

    _socket!.onDisconnect((_) {
      developer.log('WS disconnected', name: 'WsClient');
      _handlers['onDisconnect']?.call();
      if (_autoReconnect) {
        _scheduleReconnect();
      }
    });

    _socket!.onError((data) {
      developer.log('WS error: $data', name: 'WsClient');
      _handlers['onError']?.call(data);
    });

    _socket!.onConnectError((data) {
      developer.log('WS connect error: $data', name: 'WsClient');
      _handlers['onError']?.call(data);
      if (_autoReconnect) {
        _scheduleReconnect();
      }
    });

    _socket!.connect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      developer.log('WS max reconnect attempts reached', name: 'WsClient');
      return;
    }
    _cancelReconnect();
    _reconnectAttempts++;
    final delay = Duration(
      seconds: AppConstants.wsReconnectDelaySeconds * _reconnectAttempts,
    );
    developer.log('WS reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s', name: 'WsClient');
    _reconnectTimer = Timer(delay, () {
      if (!_autoReconnect) return;
      _socket?.disconnect();
      _socket?.destroy();
      _socket = null;
      _eventsAttached = false;
      _doConnect();
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void disconnect() {
    developer.log('WS disconnect', name: 'WsClient');
    _autoReconnect = false;
    _cancelReconnect();
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
    _currentWssUrl = null;
    _deviceUuid = null;
    _devicePassword = null;
    _eventsAttached = false;
    _reconnectAttempts = 0;
  }

  void on(WsEventType event, Function callback) {
    _eventHandlers[event.value] = callback;
    _socket?.off(event.value);
    _socket?.on(event.value, (data) => callback(data));
  }

  void off(WsEventType event) {
    _eventHandlers.remove(event.value);
    _socket?.off(event.value);
  }

  void _reattachEventListeners() {
    if (_eventsAttached || _socket == null) return;
    _eventHandlers.forEach((event, callback) {
      _socket!.off(event);
      _socket!.on(event, (data) => callback(data));
    });
    _eventsAttached = true;
  }

  void emit(WsEventType event, Map<String, dynamic> data) {
    _reattachEventListeners();
    developer.log('WS emit: ${event.value} data=${data.toString()}', name: 'WsClient');
    _socket?.emit(event.value, data);

  }

  void setHandlers({
    Function()? onConnect,
    Function()? onDisconnect,
    Function(dynamic)? onError,
  }) {
    if (onConnect != null) _handlers['onConnect'] = onConnect;
    if (onDisconnect != null) _handlers['onDisconnect'] = onDisconnect;
    if (onError != null) _handlers['onError'] = onError;
  }
}
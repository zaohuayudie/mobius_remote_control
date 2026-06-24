import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobius_desk_flutter/application/providers/connection_provider.dart';
import 'package:mobius_desk_flutter/core/enums.dart';
import 'package:mobius_desk_flutter/core/theme.dart';

class RemotePage extends ConsumerStatefulWidget {
  const RemotePage({super.key});

  @override
  ConsumerState<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends ConsumerState<RemotePage> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _isRendererReady = false;
  StreamSubscription? _streamSub;
  Offset _lastPanPos = Offset.zero;

  final GlobalKey _videoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();

    final connectionState = ref.read(connectionProvider);
    final rtcManager = ref.read(connectionProvider.notifier).rtcManager;

    if (connectionState.mode == ConnectionMode.control) {
      final existingStream = rtcManager.latestRemoteStream;
      if (existingStream != null) {
        _remoteRenderer.srcObject = existingStream;
      }
      _streamSub = rtcManager.remoteStream.listen((stream) {
        if (_isRendererReady && mounted) {
          _remoteRenderer.srcObject = stream;
          setState(() {});
        }
      });
    } else {
      final localStream = rtcManager.localStream;
      if (localStream != null) {
        _localRenderer.srcObject = localStream;
      }
    }

    setState(() => _isRendererReady = true);
  }

  Offset _normalizePosition(Offset globalPos) {
    final renderBox = _videoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    final localPos = renderBox.globalToLocal(globalPos);
    final size = renderBox.size;
    final x = (localPos.dx / size.width) * 1000;
    final y = (localPos.dy / size.height) * 1000;
    return Offset(x.clamp(0, 1000), y.clamp(0, 1000));
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionProvider);
    final isControl = connectionState.mode == ConnectionMode.control;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isControl)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: isControl
                  ? (details) {
                      _lastPanPos = details.globalPosition;
                    }
                  : null,
              onPanUpdate: isControl
                  ? (details) {
                      _lastPanPos = details.globalPosition;
                      final normalized = _normalizePosition(details.globalPosition);
                      ref.read(connectionProvider.notifier).sendBehavior(
                        DeskBehaviorType.mouseMove,
                        x: normalized.dx,
                        y: normalized.dy,
                      );
                    }
                  : null,
              onTap: isControl
                  ? () {
                      final normalized = _normalizePosition(_lastPanPos);
                      ref.read(connectionProvider.notifier).sendBehavior(
                        DeskBehaviorType.leftClick,
                        x: normalized.dx,
                        y: normalized.dy,
                      );
                    }
                  : null,
              child: Center(
                child: _isRendererReady
                    ? RTCVideoView(
                        _remoteRenderer,
                        key: _videoKey,
                        objectFit: RTCVideoViewObjectFit
                            .RTCVideoViewObjectFitContain,
                      )
                    : CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 3,
                      ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 240,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isRendererReady && _localRenderer.srcObject != null
                        ? RTCVideoView(
                            _localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.videocam, color: Colors.white54, size: 40),
                                SizedBox(height: 8),
                                Text('摄像头未就绪', style: TextStyle(color: Colors.white54, fontSize: 14)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x9BF527CC), Color(0x9B8BB8E8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          '正在被远程控制...',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: _ConnectionDetailCard(
              rtt: connectionState.rtt,
              packetLoss: connectionState.packetLoss,
              resolution: connectionState.currentResolution,
              framerate: connectionState.currentFramerate,
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            left: 16,
            right: 16,
            child: _ControlToolbar(
              isControl: isControl,
              onToggleMode: () {
                ref.read(connectionProvider.notifier).setMode(
                  isControl ? ConnectionMode.view : ConnectionMode.control,
                );
              },
              onDisconnect: () {
                ref.read(connectionProvider.notifier).stopRemote();
                if (context.canPop()) context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionDetailCard extends StatelessWidget {
  final int rtt;
  final double packetLoss;
  final String resolution;
  final int framerate;

  const _ConnectionDetailCard({
    required this.rtt,
    required this.packetLoss,
    required this.resolution,
    required this.framerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x9BF527CC), Color(0x9B8BB8E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('RTT: ${rtt}ms', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('丢包: ${packetLoss.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('分辨率: $resolution',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('帧率: ${framerate}fps',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ControlToolbar extends StatelessWidget {
  final bool isControl;
  final VoidCallback onToggleMode;
  final VoidCallback onDisconnect;

  const _ControlToolbar({
    required this.isControl,
    required this.onToggleMode,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xDD2D2B55), Color(0xDD1A1A3E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: onToggleMode,
            icon: Icon(
              isControl ? Icons.mouse : Icons.visibility,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              isControl ? '控制模式' : '观看模式',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.white24,
          ),
          TextButton.icon(
            onPressed: onDisconnect,
            icon: const Icon(Icons.call_end, color: AppTheme.errorColor, size: 20),
            label: const Text('断开', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

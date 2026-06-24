import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobius_desk_flutter/application/providers/device_provider.dart';
import 'package:mobius_desk_flutter/application/providers/connection_provider.dart';
import 'package:mobius_desk_flutter/application/providers/infrastructure_providers.dart';
import 'package:mobius_desk_flutter/core/enums.dart';
import 'package:mobius_desk_flutter/core/theme.dart';
import 'package:mobius_desk_flutter/presentation/widgets/device_code_card.dart';
import 'package:mobius_desk_flutter/presentation/widgets/password_input_dialog.dart';
import 'package:mobius_desk_flutter/presentation/widgets/params_config_sheet.dart';

class ConnectPage extends ConsumerStatefulWidget {
  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> with WidgetsBindingObserver {
  final _targetUuidController = TextEditingController();
  bool _verifying = false;
  bool _waitingAccept = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndConnect();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wsConnected = ref.read(connectionProvider).wsConnected;
      if (!wsConnected) {
        _connectWs();
      }
    }
  }

  Future<void> _initAndConnect() async {
    try {
      await ref.read(localStorageProvider.future);
    } catch (_) {}

    _connectWs();

    try {
      await _initDevice();
    } catch (_) {}

    if (ref.read(connectionProvider).wsConnected) {
      ref.read(connectionProvider.notifier).joinRoom();
    }
  }

  Future<void> _initDevice() async {
    final deviceState = ref.read(deviceProvider);
    if (deviceState.uuid == null) {
      try {
        await ref.read(deviceProvider.notifier).register().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      } catch (_) {}
    }
  }

  void _connectWs() {
    final wsConnected = ref.read(connectionProvider).wsConnected;
    if (!wsConnected) {
      ref.read(connectionProvider.notifier).connectWebSocket();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _targetUuidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);
    final connectionState = ref.watch(connectionProvider);

    ref.listen<MobiusConnectionState>(connectionProvider, (prev, next) {
      if (next.hasIncomingRequest && prev?.hasIncomingRequest != true) {
        _showIncomingRequestDialog(next.incomingControllerUuid!);
      }
      if (next.mode == ConnectionMode.control && _waitingAccept) {
        if (next.remoteRejected || next.remoteError != null) {
          _waitingAccept = false;
          final msg = next.remoteError ?? '对方已拒绝';
          ref.read(connectionProvider.notifier).resetRemoteState();
          Future.microtask(() {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          });
        } else if (next.remoteAccepted && !(prev?.remoteAccepted ?? false)) {
          _waitingAccept = false;
          Future.microtask(() {
            if (!mounted) return;
            context.push('/remote');
          });
        }
      }
      if (next.mode == ConnectionMode.view &&
          next.remoteSocketId != null &&
          prev?.remoteSocketId == null) {
        Future.microtask(() {
          if (!mounted) return;
          context.push('/remote');
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('MobiusDesk')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF0F8), Color(0xFFE4F0FB), Color(0xFFFEF8FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeviceCodeCard(
                  uuid: deviceState.uuid ?? '-',
                  password: deviceState.password ?? '-',
                  onRefreshPassword: () {
                    final newPwd =
                        DateTime.now().millisecondsSinceEpoch.toString().substring(5, 11);
                    ref.read(deviceProvider.notifier).updatePassword(newPwd);
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: AppTheme.whiteCardDecoration,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: AppTheme.accentBlue.withOpacity(0.15),
                               borderRadius: BorderRadius.circular(10),
                             ),
                             child: const Icon(Icons.link, color: AppTheme.accentBlue, size: 20),
                           ),
                           const SizedBox(width: 10),
                           Text('远程连接', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                             fontWeight: FontWeight.w600,
                           )),
                           const Spacer(),
                           _buildWsStatusDot(connectionState.wsConnected),
                         ],
                       ),
                      const SizedBox(height: 16),
                       TextField(
                         controller: _targetUuidController,
                         onChanged: (_) => setState(() {}),
                         decoration: const InputDecoration(
                           labelText: '远程设备码',
                           hintText: '输入目标设备码',
                           prefixIcon: Icon(Icons.devices, color: AppTheme.primaryColor),
                         ),
                       ),
                      const SizedBox(height: 16),
                      _buildConnectButton(connectionState),
                      if (connectionState.wsError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          connectionState.wsError!,
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (connectionState.remoteError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          connectionState.remoteError!,
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: AppTheme.whiteCardDecoration,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.tune, color: AppTheme.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text('连接参数', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                            ],
                          ),
                          TextButton(
                            onPressed: _showParamsSheet,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            child: const Text('修改'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildParamRow(Icons.speed, '码率', '${connectionState.params.maxBitrate} kbps'),
                      _buildParamRow(Icons.videocam, '帧率', '${connectionState.params.maxFramerate} fps'),
                      _buildParamRow(Icons.aspect_ratio, '分辨率', connectionState.params.resolution.label),
                      _buildParamRow(Icons.high_quality, '视频提示', connectionState.params.videoHint.label),
                      _buildParamRow(Icons.graphic_eq, '音频提示', connectionState.params.audioHint.label),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectButton(MobiusConnectionState connectionState) {
    final isConnected = connectionState.wsConnected;
    final isConnecting = connectionState.wsConnecting;
    final isRemoteConnecting = connectionState.remoteConnecting;
    final hasWsError = connectionState.wsError != null;
    final isVerifying = _verifying;
    final hasTarget = _targetUuidController.text.trim().isNotEmpty;

    LinearGradient gradient;
    List<BoxShadow>? boxShadow;
    Widget child;
    VoidCallback? onTap;

    if (isVerifying || _waitingAccept) {
      gradient = LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.6), AppTheme.primaryColor.withOpacity(0.6)]);
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 8),
          Text(_waitingAccept ? '正在等待对方接受...' : '正在验证设备...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      );
      onTap = null;
    } else if (isConnected && hasTarget) {
      gradient = AppTheme.buttonGradient;
      boxShadow = [
        BoxShadow(
          color: AppTheme.primaryColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.link, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('连接远程设备', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      );
      onTap = _handleConnect;
    } else if (isConnected && !hasTarget) {
      gradient = LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.4), AppTheme.primaryColor.withOpacity(0.4)]);
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.link, color: Colors.white54, size: 20),
          SizedBox(width: 8),
          Text('连接远程设备', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      );
      onTap = null;
    } else if (isConnecting) {
      gradient = LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.6), AppTheme.primaryColor.withOpacity(0.6)]);
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 8),
          Text('连接中...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      );
      onTap = null;
    } else if (hasWsError) {
      gradient = LinearGradient(colors: [AppTheme.errorColor.withOpacity(0.7), AppTheme.errorColor.withOpacity(0.7)]);
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.refresh, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('连接失败，点击重试', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      );
      onTap = _connectWs;
    } else {
      gradient = LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade400]);
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.link_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('未连接服务器', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      );
      onTap = _connectWs;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildWsStatusDot(bool connected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: connected ? Colors.green : Colors.grey.shade400,
            shape: BoxShape.circle,
            boxShadow: connected
                ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 4)]
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          connected ? '已连接' : '未连接',
          style: TextStyle(
            color: connected ? Colors.green : Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildParamRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryLight),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _handleConnect() async {
    final targetUuid = _targetUuidController.text.trim();
    if (targetUuid.isEmpty) return;

    final password = await showDialog<String>(
      context: context,
      builder: (_) => const PasswordInputDialog(),
    );
    if (password == null || password.isEmpty) return;

    setState(() => _verifying = true);
    final valid = await ref.read(deviceProvider.notifier).verifyDevice(
      uuid: targetUuid,
      password: password,
    );
    if (!valid) {
      setState(() => _verifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('设备码或密码错误'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final online = await ref.read(deviceProvider.notifier).checkOnline(targetUuid);
    setState(() => _verifying = false);
    if (!online) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('目标设备不在线'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    setState(() => _waitingAccept = true);
    ref.read(connectionProvider.notifier).startRemote(
      targetUuid: targetUuid,
      targetPassword: password,
    );
  }

  void _showIncomingRequestDialog(String controllerUuid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.computer, color: AppTheme.primaryColor, size: 24),
            SizedBox(width: 10),
            Text('远程控制请求', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('有设备请求远程控制此设备', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            Text('主控端设备码:', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.15)),
              ),
              child: Text(controllerUuid, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(connectionProvider.notifier).rejectIncoming();
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('拒绝'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(connectionProvider.notifier).acceptIncoming();
              Navigator.of(ctx).pop();

            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('接受'),
          ),
        ],
      ),
    );
  }

  void _showParamsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ParamsConfigSheet(
        params: ref.read(connectionProvider).params,
        onChanged: (params) {
          ref.read(connectionProvider.notifier).changeParams(params);
        },
      ),
    );
  }
}

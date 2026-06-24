import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobius_desk_flutter/application/providers/connection_provider.dart';
import 'package:mobius_desk_flutter/application/providers/device_provider.dart';
import 'package:mobius_desk_flutter/core/theme.dart';
import 'package:mobius_desk_flutter/domain/models/device.dart';
import 'package:mobius_desk_flutter/presentation/widgets/password_input_dialog.dart';

class DevicePage extends ConsumerStatefulWidget {
  const DevicePage({super.key});

  @override
  ConsumerState<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends ConsumerState<DevicePage> {
  List<Device> _devices = [];
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    if (!_loaded && !_loading) {
      _loaded = true;
      _loadDevices();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('在线设备')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF0F8), Color(0xFFE4F0FB), Color(0xFFFEF8FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _loadDevices,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('重试'),
                                ),
                              ],
                            ),
                          )
                        : _devices.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.devices_other, size: 48, color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    Text('暂无其他在线设备', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                color: AppTheme.primaryColor,
                                onRefresh: _loadDevices,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _devices.length,
                                  itemBuilder: (_, index) => _DeviceCard(
                                    device: _devices[index],
                                    onConnect: () => _connectDevice(_devices[index]),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadDevices() async {
    setState(() { _loading = true; _error = null; });
    try {
      final devices = await ref.read(deviceProvider.notifier).listDevices();
      final myUuid = ref.read(deviceProvider).uuid;
      if (!mounted) return;
      setState(() {
        _devices = devices.where((d) => d.uuid != myUuid).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _connectDevice(Device device) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const PasswordInputDialog(),
    );
    if (password == null || password.isEmpty) return;

    if (!ref.read(connectionProvider).wsConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先连接服务器'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    ref.read(connectionProvider.notifier).startRemote(
      targetUuid: device.uuid,
      targetPassword: password,
    );

    final state = await ref.read(connectionProvider.notifier).stream.firstWhere((s) => !s.remoteConnecting);
    if (state.remoteError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.remoteError!),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }
    if (state.remoteSocketId != null && mounted) {
      context.push('/remote');
    }
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onConnect;

  const _DeviceCard({required this.device, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.whiteCardDecoration,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.computer, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.uuid,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: device.online ? Colors.green : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device.online ? '在线' : '离线',
                      style: TextStyle(
                        color: device.online ? Colors.green : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.buttonGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: device.online ? onConnect : null,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '连接',
                    style: TextStyle(
                      color: device.online ? Colors.white : Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobius_desk_flutter/application/providers/setting_provider.dart';
import 'package:mobius_desk_flutter/core/constants.dart';
import 'package:mobius_desk_flutter/core/theme.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingState = ref.watch(settingProvider);
    final notifier = ref.read(settingProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('设置')),
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
                Container(
                  decoration: AppTheme.whiteCardDecoration,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.dns, color: AppTheme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('服务器配置', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ServerUrlField(
                        label: 'WSS 地址',
                        value: settingState.wssUrl,
                        onSave: (v) => notifier.setWssUrl(v),
                      ),
                      const SizedBox(height: 12),
                      _ServerUrlField(
                        label: 'API 地址',
                        value: settingState.apiUrl,
                        onSave: (v) => notifier.setApiUrl(v),
                      ),
                      const SizedBox(height: 12),
                      _ServerUrlField(
                        label: 'COTURN 地址',
                        value: settingState.coturnUrl ?? '',
                        onSave: (v) => notifier.setCoturnUrl(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: AppTheme.whiteCardDecoration,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('应用信息', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('版本号', style: TextStyle(color: AppTheme.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('1.0.0', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
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
}

class _ServerUrlField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onSave;

  const _ServerUrlField({
    required this.label,
    required this.value,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => onSave(controller.text),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text('保存', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

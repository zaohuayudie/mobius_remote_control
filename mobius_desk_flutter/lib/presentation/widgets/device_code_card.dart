import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobius_desk_flutter/core/theme.dart';

class DeviceCodeCard extends StatelessWidget {
  final String uuid;
  final String password;
  final VoidCallback? onRefreshPassword;

  const DeviceCodeCard({
    super.key,
    required this.uuid,
    required this.password,
    this.onRefreshPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.gradientBoxDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.devices, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text('本机设备', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48, child: Text('设备码', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary, fontSize: 13))),
                Expanded(
                  child: Text(uuid,
                      style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textPrimary, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                _copyButton(() {
                  Clipboard.setData(ClipboardData(text: uuid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('已复制设备码'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.9),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48, child: Text('密码', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary, fontSize: 13))),
                Expanded(
                  child: Text(password, style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                _copyButton(() {
                  Clipboard.setData(ClipboardData(text: password));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('已复制密码'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.9),
                    ),
                  );
                }),
                const SizedBox(width: 2),
                _iconButton(Icons.refresh, onRefreshPassword),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyButton(VoidCallback onTap) {
    return Material(
      color: AppTheme.primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.copy, size: 16, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: AppTheme.primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.refresh, size: 16, color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}

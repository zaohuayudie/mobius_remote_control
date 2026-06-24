import 'package:flutter/material.dart';
import 'package:mobius_desk_flutter/core/theme.dart';

class PasswordInputDialog extends StatefulWidget {
  const PasswordInputDialog({super.key});

  @override
  State<PasswordInputDialog> createState() => _PasswordInputDialogState();
}

class _PasswordInputDialogState extends State<PasswordInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('输入连接密码'),
        ],
      ),
      content: TextField(
        controller: _controller,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: '被控端密码',
          hintText: '请输入远程设备密码',
          prefixIcon: Icon(Icons.vpn_key, color: AppTheme.primaryColor),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          child: const Text('取消'),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.buttonGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(_controller.text),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('确认', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

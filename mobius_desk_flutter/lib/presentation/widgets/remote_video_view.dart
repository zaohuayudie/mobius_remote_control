import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RemoteVideoView extends StatelessWidget {
  final Widget child;

  const RemoteVideoView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(child: child);
  }
}
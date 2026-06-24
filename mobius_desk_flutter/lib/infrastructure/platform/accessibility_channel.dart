import 'package:flutter/services.dart';

class AccessibilityChannel {
  static const _channel = MethodChannel('com.mobiusdesk.accessibility');

  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityEnabled') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } on PlatformException {
      // ignore
    }
  }

  static Future<void> performClick(double x, double y) async {
    try {
      await _channel.invokeMethod<void>('performClick', {'x': x, 'y': y});
    } on PlatformException {
      // ignore
    }
  }

  static Future<void> performLongClick(double x, double y) async {
    try {
      await _channel.invokeMethod<void>('performLongClick', {'x': x, 'y': y});
    } on PlatformException {
      // ignore
    }
  }

  static Future<void> performSwipe(
      double startX, double startY, double endX, double endY, int duration) async {
    try {
      await _channel.invokeMethod<void>('performSwipe', {
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'duration': duration,
      });
    } on PlatformException {
      // ignore
    }
  }

  static Future<void> performScroll(double x, double y, double dx, double dy) async {
    try {
      await _channel.invokeMethod<void>('performScroll', {
        'x': x,
        'y': y,
        'dx': dx,
        'dy': dy,
      });
    } on PlatformException {
      // ignore
    }
  }

  static Future<void> performMove(double x, double y) async {
    try {
      await _channel.invokeMethod<void>('performMove', {'x': x, 'y': y});
    } on PlatformException {
      // ignore
    }
  }
}

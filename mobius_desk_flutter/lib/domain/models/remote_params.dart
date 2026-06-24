import 'package:mobius_desk_flutter/core/enums.dart';

class RemoteParams {
  final int maxBitrate;
  final int maxFramerate;
  final Resolution resolution;
  final VideoContentHint videoHint;
  final AudioContentHint audioHint;

  const RemoteParams({
    this.maxBitrate = 2000,
    this.maxFramerate = 60,
    this.resolution = Resolution.p1080,
    this.videoHint = VideoContentHint.detailed,
    this.audioHint = AudioContentHint.speech,
  });

  RemoteParams copyWith({
    int? maxBitrate,
    int? maxFramerate,
    Resolution? resolution,
    VideoContentHint? videoHint,
    AudioContentHint? audioHint,
  }) =>
      RemoteParams(
        maxBitrate: maxBitrate ?? this.maxBitrate,
        maxFramerate: maxFramerate ?? this.maxFramerate,
        resolution: resolution ?? this.resolution,
        videoHint: videoHint ?? this.videoHint,
        audioHint: audioHint ?? this.audioHint,
      );

  Map<String, dynamic> toWsJson() => {
        'max_bitrate': maxBitrate,
        'max_framerate': maxFramerate,
        'resolution': resolution.label,
        'video_hint': videoHint.value,
        'audio_hint': audioHint.value,
      };
}
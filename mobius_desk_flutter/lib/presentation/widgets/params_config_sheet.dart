import 'package:flutter/material.dart';
import 'package:mobius_desk_flutter/core/enums.dart';
import 'package:mobius_desk_flutter/core/theme.dart';
import 'package:mobius_desk_flutter/domain/models/remote_params.dart';

class ParamsConfigSheet extends StatefulWidget {
  final RemoteParams params;
  final ValueChanged<RemoteParams> onChanged;

  const ParamsConfigSheet({
    super.key,
    required this.params,
    required this.onChanged,
  });

  @override
  State<ParamsConfigSheet> createState() => _ParamsConfigSheetState();
}

class _ParamsConfigSheetState extends State<ParamsConfigSheet> {
  late int _maxBitrate;
  late int _maxFramerate;
  late Resolution _resolution;
  late VideoContentHint _videoHint;
  late AudioContentHint _audioHint;

  @override
  void initState() {
    super.initState();
    _maxBitrate = widget.params.maxBitrate;
    _maxFramerate = widget.params.maxFramerate;
    _resolution = widget.params.resolution;
    _videoHint = widget.params.videoHint;
    _audioHint = widget.params.audioHint;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text('连接参数', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
            const SizedBox(height: 20),
            _buildSliderSection(Icons.speed, '码率', '${_maxBitrate} kbps', _maxBitrate.toDouble(), 500, 4000, 7,
                (v) => setState(() => _maxBitrate = v.toInt())),
            const SizedBox(height: 12),
            _buildSliderSection(Icons.videocam, '帧率', '${_maxFramerate} fps', _maxFramerate.toDouble(), 15, 120, 7,
                (v) => setState(() => _maxFramerate = v.toInt())),
            const SizedBox(height: 12),
            _buildChipSection<Resolution>(
              icon: Icons.aspect_ratio,
              label: '分辨率',
              values: Resolution.values,
              selected: _resolution,
              labelBuilder: (r) => r.label,
              onChanged: (v) => setState(() => _resolution = v),
            ),
            const SizedBox(height: 12),
            _buildChipSection<VideoContentHint>(
              icon: Icons.high_quality,
              label: '视频提示',
              values: VideoContentHint.values,
              selected: _videoHint,
              labelBuilder: (v) => v.label,
              onChanged: (v) => setState(() => _videoHint = v),
            ),
            const SizedBox(height: 12),
            _buildChipSection<AudioContentHint>(
              icon: Icons.graphic_eq,
              label: '音频提示',
              values: AudioContentHint.values,
              selected: _audioHint,
              labelBuilder: (a) => a.label,
              onChanged: (v) => setState(() => _audioHint = v),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.buttonGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    widget.onChanged(RemoteParams(
                      maxBitrate: _maxBitrate,
                      maxFramerate: _maxFramerate,
                      resolution: _resolution,
                      videoHint: _videoHint,
                      audioHint: _audioHint,
                    ));
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('确认', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipSection<T>({
    required IconData icon,
    required String label,
    required List<T> values,
    required T selected,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            final isSelected = v == selected;
            return ChoiceChip(
              label: Text(labelBuilder(v)),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor.withOpacity(0.15),
              backgroundColor: Colors.grey.shade100,
              side: isSelected
                  ? BorderSide(color: AppTheme.primaryColor, width: 1.5)
                  : BorderSide(color: Colors.grey.shade300),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => onChanged(v),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliderSection(IconData icon, String label, String value, double current, double min, double max, int divisions, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const Spacer(),
            Text(value, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primaryColor,
            thumbColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryLight.withOpacity(0.3),
            overlayColor: AppTheme.primaryColor.withOpacity(0.1),
          ),
          child: Slider(
            value: current,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_alsady_web/core/constants/app_colors.dart';
import 'package:speech_to_text_alsady_web/features/home/controllers/home_controller.dart';
import 'package:speech_to_text_alsady_web/widgets/waveform_animation.dart';
import 'sound_level_meter.dart';
import 'status_banner.dart';

class LiveMicTab extends StatelessWidget {
  const LiveMicTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Obx(() {
      final activeMicColor =
          ctrl.isRecording.value ? AppColors.redAccent : AppColors.blueAccent;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Waveform / preview / loading indicator
          Expanded(
            child: Center(child: Obx(() {
              if (ctrl.isProcessingRecording.value) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(strokeWidth: 4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ctrl.isArabic.value
                          ? 'جاري معالجة التسجيل...'
                          : 'Processing recording...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }
              if (ctrl.hasAudioPreview.value && !ctrl.isRecording.value) {
                return _AudioPreviewCard();
              }
              return WaveformAnimation(
                isRecording: ctrl.isRecording.value,
                activeColor: activeMicColor,
              );
            })),
          ),

          // Mic Controller Button
          Semantics(
            label: ctrl.isRecording.value ? 'Stop recording' : 'Start recording',
            child: AbsorbPointer(
              absorbing: ctrl.isProcessingRecording.value,
              child: ElevatedButton(
                onPressed: () {
                  if (ctrl.isRecording.value) {
                    ctrl.stopRecording();
                  } else {
                    ctrl.startRecording();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctrl.isProcessingRecording.value
                      ? Colors.grey
                      : activeMicColor,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(22),
                  elevation: 6,
                  shadowColor: activeMicColor.withValues(alpha: 0.4),
                ),
                child: Icon(
                  ctrl.isProcessingRecording.value
                      ? Icons.hourglass_bottom_rounded
                      : ctrl.isRecording.value
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                  size: 32,
                ),
              ),
            ),
          ),

          // Sound level meter (only during active recording)
          if (ctrl.isRecording.value) ...[
            const SizedBox(height: 12),
            const SoundLevelMeter(),
          ],

          // Processing indicator text
          if (ctrl.isProcessingRecording.value) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    ctrl.isArabic.value
                        ? 'جارٍ معالجة التسجيل الصوتي...'
                        : 'Processing recording...',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          // Device selector
          if (ctrl.availableDevices.isNotEmpty && !ctrl.isRecording.value) ...[
            const SizedBox(height: 16),
            Obx(() {
              final devices = ctrl.availableDevices;
              return SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  initialValue: ctrl.selectedDeviceId.value.isNotEmpty
                      ? ctrl.selectedDeviceId.value
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: ctrl.isArabic.value ? 'جهاز الإدخال' : 'Input Device',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(ctrl.isArabic.value ? 'افتراضي' : 'Default'),
                    ),
                    for (final d in devices)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text(
                          d.label.isNotEmpty ? d.label : d.id,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (val) {
                    ctrl.selectedDeviceId(val ?? '');
                  },
                ),
              );
            }),
          ],

          const SizedBox(height: 20),

          // Status banner
          const StatusBanner(),
        ],
      );
    });
  }
}

class _AudioPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final isDark = ctrl.isDarkMode.value;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 36, color: Colors.green),
          ),
          const SizedBox(height: 10),
          Text(
            ctrl.isArabic.value ? 'التسجيل جاهز' : 'Recording Ready',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            ctrl.isArabic.value ? 'اضغط لتشغيل التسجيل' : 'Tap to preview',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ctrl.playPreview,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(ctrl.isArabic.value ? 'تشغيل' : 'Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

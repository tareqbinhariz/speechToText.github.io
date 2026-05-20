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
          // Waveform or loading indicator
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

          const SizedBox(height: 20),

          // Status banner
          const StatusBanner(),
        ],
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_alsady_web/features/home/controllers/home_controller.dart';

class SoundLevelMeter extends StatelessWidget {
  const SoundLevelMeter({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Obx(() {
      if (!ctrl.isRecording.value) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _animatedDot(Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              ctrl.isArabic.value ? '🔴 تسجيل...' : '🔴 Recording...',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _animatedDot(Color color) {
    return SizedBox(
      width: 10,
      height: 10,
      child: AnimatedBuilder(
        animation: const AlwaysStoppedAnimation(0),
        builder: (context, child) {
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

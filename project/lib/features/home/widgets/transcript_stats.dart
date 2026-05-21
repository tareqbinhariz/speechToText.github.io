import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/home_controller.dart';

class TranscriptStats extends StatelessWidget {
  const TranscriptStats({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();

    return Obx(() {
      ctrl.textVersion.value;
      final text = ctrl.textController.text;
      final wordCount = text.isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
      final charCount = text.length;
      final readTime = (wordCount / 200).ceil();
      final isDark = ctrl.isDarkMode.value;
      final borderThemeColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black12 : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderThemeColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.notes_rounded,
              label: ctrl.isArabic.value ? 'الكلمات' : 'Words',
              value: '$wordCount',
              isDark: isDark,
            ),
            _buildDivider(borderThemeColor),
            _buildStatItem(
              icon: Icons.abc_rounded,
              label: ctrl.isArabic.value ? 'الحروف' : 'Chars',
              value: '$charCount',
              isDark: isDark,
            ),
            _buildDivider(borderThemeColor),
            _buildStatItem(
              icon: Icons.timer_outlined,
              label: ctrl.isArabic.value ? 'وقت القراءة' : 'Read Time',
              value: ctrl.isArabic.value ? '$readTime د' : '$readTime m',
              isDark: isDark,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.blueAccent),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      width: 1.5,
      height: 24,
      color: color,
    );
  }
}

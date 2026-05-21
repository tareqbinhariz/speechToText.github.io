import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_alsady_web/features/home/controllers/home_controller.dart';
import 'status_banner.dart';

class TranscriptOutput extends StatelessWidget {
  const TranscriptOutput({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Obx(() {
      ctrl.textVersion.value;
      final isDark = ctrl.isDarkMode.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ctrl.isArabic.value ? '📝 النص المنسوخ' : '📝 Transcript Text',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (ctrl.isTranslating.value)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                InkWell(
                  onTap: ctrl.translateResultText,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.translate_rounded, size: 14, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          ctrl.transcriptIsArabic.value
                              ? (ctrl.isArabic.value ? 'ترجم للإنجليزية' : 'Translate to English')
                              : (ctrl.isArabic.value ? 'ترجم للعربية' : 'Translate to Arabic'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: ctrl.textController,
                maxLines: null,
                textDirection: ctrl.isArabic.value ? TextDirection.rtl : TextDirection.ltr,
                textAlign: ctrl.isArabic.value ? TextAlign.right : TextAlign.left,
                style: const TextStyle(fontSize: 16, height: 1.6),
                decoration: InputDecoration(
                  hintText: ctrl.isArabic.value
                      ? 'النص المنسوخ سيظهر هنا تلقائياً، أو يمكنك كتابته وتعديله مباشرة...'
                      : 'Transcribed text will appear here automatically, or you can edit/type directly...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          const StatusBanner(),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: ctrl.copyText,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(ctrl.isArabic.value ? 'نسخ النص' : 'Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: ctrl.textController.text.isNotEmpty ? ctrl.summarizeSelectedText : null,
                  icon: ctrl.isSummarizing.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    ctrl.isSummarizing.value
                        ? (ctrl.isArabic.value ? 'جاري التلخيص...' : 'Summarizing...')
                        : (ctrl.isArabic.value ? 'تلخيص' : 'Summarize'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: ctrl.textController.text.isNotEmpty ? ctrl.downloadTextFile : null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(ctrl.isArabic.value ? 'حفظ كملف' : 'Export File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: ctrl.clearText,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                tooltip: ctrl.isArabic.value ? 'مسح الكل' : 'Clear All',
              ),
            ],
          ),
        ],
      );
    });
  }
}

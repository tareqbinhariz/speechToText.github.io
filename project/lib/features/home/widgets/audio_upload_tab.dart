import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_alsady_web/features/home/controllers/home_controller.dart';

class AudioUploadTab extends StatelessWidget {
  const AudioUploadTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Obx(() {
      final hasFile = ctrl.selectedFile.value != null;
      final isDark = ctrl.isDarkMode.value;
      final textSecondary = isDark ? Colors.white60 : Colors.black54;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!hasFile) ...[
            Expanded(
              child: InkWell(
                onTap: ctrl.pickAudioFile,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black12 : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.4),
                      style: BorderStyle.values[1],
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          size: 44,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ctrl.isArabic.value
                            ? 'اسحب الملف الصوتي هنا أو انقر للاختيار'
                            : 'Drag & drop audio file or click to select',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ctrl.isArabic.value
                            ? 'يدعم صيغ MP3, WAV, M4A, OGG, FLAC'
                            : 'Supports MP3, WAV, M4A, OGG, FLAC formats',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 220),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.audio_file_rounded, size: 48, color: Colors.blueAccent),
                      const SizedBox(height: 12),
                      Text(
                        ctrl.selectedFile.value!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ctrl.isArabic.value
                            ? 'الحجم: ${(ctrl.selectedFile.value!.size / 1024 / 1024).toStringAsFixed(2)} ميجابايت'
                            : 'Size: ${(ctrl.selectedFile.value!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          ctrl.selectedFile(null);
                          ctrl.fileTranscriptionStatus('');
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.redAccent),
                        label: Text(
                          ctrl.isArabic.value ? 'تغيير الملف' : 'Change File',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (ctrl.effectiveApiKey.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ctrl.isArabic.value
                          ? 'مفتاح API غير مضاف. يرجى تهيئته أولاً من الإعدادات للنسخ.'
                          : 'API Key missing. Please set it in settings to transcribe.',
                      style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (ctrl.isTranscribingFile.value || ctrl.fileTranscriptionStatus.value.isNotEmpty) ...[
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ctrl.fileTranscriptionStatus.value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  if (ctrl.isTranscribingFile.value) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ctrl.transcriptionProgress.value,
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          ElevatedButton.icon(
            onPressed: hasFile && !ctrl.isTranscribingFile.value ? ctrl.transcribeSelectedFile : null,
            icon: ctrl.isTranscribingFile.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.rocket_launch_rounded, size: 18),
            label: Text(
              ctrl.isTranscribingFile.value
                  ? (ctrl.isArabic.value ? 'جاري النسخ حالياً...' : 'Transcribing...')
                  : (ctrl.isArabic.value ? 'ابدأ النسخ الذكي' : 'Start Smart Transcription'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: Colors.blueAccent.withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    });
  }
}

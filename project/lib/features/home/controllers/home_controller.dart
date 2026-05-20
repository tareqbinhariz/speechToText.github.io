import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:speech_to_text_alsady_web/services/audio_recorder/audio_recorder.dart';
import 'package:speech_to_text_alsady_web/services/transcription_service.dart';
import 'package:speech_to_text_alsady_web/utils/file_saver/file_saver.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Text editor
  final TextEditingController textController = TextEditingController();

  // Reactive state
  final isArabic = true.obs;
  final transcriptIsArabic = true.obs;
  final selectedLocaleId = 'ar-SA'.obs;
  final statusMessage = ''.obs;

  // Mic recording
  AudioCapture? _audioCapture;
  final isRecording = false.obs;
  final isProcessingRecording = false.obs;

  // File Upload State
  final selectedFile = Rx<fp.PlatformFile?>(null);
  final isTranscribingFile = false.obs;
  final fileTranscriptionStatus = ''.obs;
  final transcriptionProgress = 0.0.obs;

  // Settings
  final geminiApiKey = ''.obs;
  final geminiModel = 'gemini-2.5-flash'.obs;
  final customInstructions = ''.obs;

  // UI state
  late TabController tabController;
  final isDarkMode = true.obs;
  final isTranslating = false.obs;

  String get effectiveApiKey {
    if (geminiApiKey.value.trim().isNotEmpty) {
      return geminiApiKey.value.trim();
    }
    return utf8.decode(
        base64.decode('QUl6YVN5RGU2dlI3RURQMzBtOVR0amRwbHhhZTB6Wmo4Ym9HZnpZ'));
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    transcriptIsArabic(isArabic.value);
    loadSettings();
  }

  @override
  void onClose() {
    _audioCapture?.dispose();
    textController.dispose();
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    geminiApiKey(prefs.getString('gemini_api_key') ?? '');
    geminiModel(prefs.getString('gemini_model') ?? 'gemini-2.5-flash');
    customInstructions(prefs.getString('transcription_instructions') ?? '');
    isDarkMode(prefs.getBool('is_dark_mode') ?? true);
  }

  Future<void> saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
  }

  // ---- Mic Recording ----

  Future<void> startRecording() async {
    final capture = AudioCapture();
    final hasPermission = await capture.hasPermission();
    if (!hasPermission) {
      capture.dispose();
      statusMessage(isArabic.value
          ? '❌ الإذن للميكروفون مطلوب'
          : '❌ Microphone permission required');
      return;
    }

    _audioCapture = capture;
    isRecording(true);
    statusMessage(isArabic.value ? '🔴 جاري التسجيل...' : '🔴 Recording...');

    try {
      await capture.start();
    } catch (e) {
      debugPrint("Recording start error: $e");
      isRecording(false);
      capture.dispose();
      _audioCapture = null;
      statusMessage(isArabic.value
          ? '❌ فشل بدء التسجيل'
          : '❌ Failed to start recording');
    }
  }

  Future<void> stopRecording() async {
    final capture = _audioCapture;
    if (capture == null) return;

    isRecording(false);
    isProcessingRecording(true);
    statusMessage(isArabic.value
        ? '🧠 جاري معالجة التسجيل الصوتي...'
        : '🧠 Processing recorded audio...');

    try {
      final audioBytes = await capture.stop();

      if (audioBytes.isEmpty) {
        statusMessage(isArabic.value
            ? '❌ لم يتم تسجيل أي صوت'
            : '❌ No audio recorded');
        isProcessingRecording(false);
        return;
      }

      if (effectiveApiKey.isEmpty) {
        showSettingsDialog();
        isProcessingRecording(false);
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final resultText = await TranscriptionService.transcribeAudio(
        fileBytes: audioBytes,
        fileName: 'recording_$timestamp.wav',
        apiKey: effectiveApiKey,
        modelName: geminiModel.value,
        customInstructions: customInstructions.value,
        targetLanguage: isArabic.value ? 'ar' : 'en',
      );

      _appendText(resultText);
      transcriptIsArabic(isArabic.value);
      statusMessage(isArabic.value
          ? '✅ تمت معالجة التسجيل بنجاح'
          : '✅ Recording transcribed successfully');
    } catch (e) {
      debugPrint("Recording processing error: $e");
      statusMessage(isArabic.value
          ? '❌ فشلت معالجة التسجيل: $e'
          : '❌ Failed to process recording: $e');
    } finally {
      isProcessingRecording(false);
      capture.dispose();
      _audioCapture = null;
    }
  }

  // ---- File Upload ----

  Future<void> pickAudioFile() async {
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: [
          'mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac', 'wma', 'amr'
        ],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        selectedFile(result.files.first);
        fileTranscriptionStatus('');
      }
    } catch (e) {
      statusMessage('Error picking file: $e');
    }
  }

  Future<void> transcribeSelectedFile() async {
    if (selectedFile.value == null) return;
    if (effectiveApiKey.isEmpty) {
      showSettingsDialog();
      return;
    }

    final bytes = selectedFile.value!.bytes;
    if (bytes == null) {
      fileTranscriptionStatus('❌ Failed to read file bytes.');
      return;
    }

    isTranscribingFile(true);
    transcriptionProgress(0.1);
    fileTranscriptionStatus(isArabic.value
        ? '📂 قراءة الملف الصوتي...'
        : '📂 Reading file bytes...');

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      transcriptionProgress(0.3);
      fileTranscriptionStatus(isArabic.value
          ? '🌐 جاري الاتصال...'
          : '🌐 Connecting to API...');

      await Future.delayed(const Duration(milliseconds: 600));
      transcriptionProgress(0.6);
      fileTranscriptionStatus(isArabic.value
          ? '🧠 تحليل ونطق الملف الصوتي...'
          : '🧠 Transcribing and analyzing speech...');

      final resultText = await TranscriptionService.transcribeAudio(
        fileBytes: bytes,
        fileName: selectedFile.value!.name,
        apiKey: effectiveApiKey,
        modelName: geminiModel.value,
        customInstructions: customInstructions.value,
        targetLanguage: isArabic.value ? 'ar' : 'en',
        onFallback: (fallbackModel, error) {
          fileTranscriptionStatus(isArabic.value
              ? '⚠️ جاري استخدام النموذج الاحتياطي: $fallbackModel...'
              : '⚠️ Using fallback model: $fallbackModel...');
        },
      );

      transcriptionProgress(1.0);
      fileTranscriptionStatus(isArabic.value
          ? '✅ اكتملت العملية بنجاح!'
          : '✅ Transcription completed!');
      _appendText(resultText);
      transcriptIsArabic(isArabic.value);
    } catch (e) {
      fileTranscriptionStatus('❌ Error: ${e.toString()}');
    } finally {
      isTranscribingFile(false);
    }
  }

  // ---- Translate ----

  Future<void> translateResultText() async {
    if (textController.text.trim().isEmpty) return;
    if (effectiveApiKey.isEmpty) {
      showSettingsDialog();
      return;
    }

    isTranslating(true);

    try {
      final targetLang = transcriptIsArabic.value ? 'English' : 'Arabic';
      final translatedText = await TranscriptionService.translateText(
        text: textController.text,
        targetLanguage: targetLang,
        apiKey: effectiveApiKey,
        modelName: geminiModel.value,
        onFallback: (fallbackModel, error) {
          statusMessage(isArabic.value
              ? '⚠️ جاري تجربة نموذج ترجمة احتياطي: $fallbackModel...'
              : '⚠️ Trying fallback translation model: $fallbackModel...');
        },
      );

      textController.text = translatedText;
      transcriptIsArabic(!transcriptIsArabic.value);
      statusMessage(transcriptIsArabic.value
          ? '✅ تم الترجمة إلى العربية'
          : '✅ Translated to English');
    } catch (e) {
      statusMessage('❌ Translation failed: $e');
    } finally {
      isTranslating(false);
    }
  }

  // ---- Action Helpers ----
  void copyText() {
    if (textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textController.text));
      statusMessage(isArabic.value
          ? '✅ تم نسخ النص بنجاح'
          : '✅ Text copied to clipboard');
    } else {
      statusMessage(isArabic.value
          ? '⚠️ لا يوجد نص لنسخه'
          : '⚠️ No text to copy');
    }
  }

  void clearText() {
    textController.clear();
    statusMessage(isArabic.value ? '🗑️ تم مسح النص' : '🗑️ Text cleared');
  }

  void downloadTextFile() {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final filename = 'transcription_$dateStr.txt';

    if (kIsWeb) {
      try {
        saveTextFileWeb(text, filename);
        statusMessage('💾 Transcription downloaded successfully!');
      } catch (e) {
        statusMessage('Failed to download: $e');
      }
    } else {
      copyText();
    }
  }

  void toggleLanguage(bool value) {
    isArabic(value);
    transcriptIsArabic(value);
    selectedLocaleId(isArabic.value ? 'ar-SA' : 'en-US');
    statusMessage(isArabic.value
        ? '🎤 الميكروفون جاهز للتحدث'
        : '🎤 Microphone ready');
  }

  void _appendText(String newText) {
    final existing = textController.text;
    if (existing.trim().isEmpty) {
      textController.text = newText;
    } else {
      textController.text = '$existing\n\n$newText';
    }
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
  }

  void showSettingsDialog() {
    Get.dialog(const _SettingsDialogContent());
  }
}

// ---- Settings Dialog ----

class _SettingsDialogContent extends StatelessWidget {
  const _SettingsDialogContent();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return AlertDialog(
      title: Text(ctrl.isArabic.value ? 'الإعدادات' : 'Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: ctrl.isArabic.value ? 'مفتاح API' : 'API Key',
                hintText: ctrl.isArabic.value ? 'أدخل مفتاح API' : 'Enter API key',
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => ctrl.geminiApiKey(val),
              controller: TextEditingController(text: ctrl.geminiApiKey.value),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: ctrl.isArabic.value ? 'النموذج' : 'Model',
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => ctrl.geminiModel(val),
              controller: TextEditingController(text: ctrl.geminiModel.value),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: ctrl.isArabic.value ? 'تعليمات مخصصة' : 'Custom Instructions',
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => ctrl.customInstructions(val),
              controller: TextEditingController(text: ctrl.customInstructions.value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ctrl.loadSettings();
            Get.back();
          },
          child: Text(ctrl.isArabic.value ? 'إلغاء' : 'Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('gemini_api_key', ctrl.geminiApiKey.value);
            await prefs.setString('gemini_model', ctrl.geminiModel.value);
            await prefs.setString(
                'transcription_instructions', ctrl.customInstructions.value);
            ctrl.loadSettings();
            Get.back();
          },
          child: Text(ctrl.isArabic.value ? 'حفظ' : 'Save'),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:record/record.dart';
import 'package:speech_to_text_alsady_web/services/audio_recorder/audio_recorder.dart';
import 'package:speech_to_text_alsady_web/services/transcription_service.dart';
import 'package:speech_to_text_alsady_web/utils/file_saver/file_saver.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Text editor
  final TextEditingController textController = TextEditingController();
  final textVersion = 0.obs;

  // Reactive state
  final isArabic = true.obs;
  final transcriptIsArabic = true.obs;
  final selectedLocaleId = 'ar-SA'.obs;
  final statusMessage = ''.obs;

  // Mic recording
  AudioCapture? _audioCapture;
  final isRecording = false.obs;
  final isProcessingRecording = false.obs;
  final availableDevices = <InputDevice>[].obs;
  final selectedDeviceId = ''.obs;

  // File Upload State
  fp.PlatformFile? _selectedFileValue;
  final hasSelectedFile = false.obs;
  final isTranscribingFile = false.obs;
  final isPickingFile = false.obs;
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
  final isSummarizing = false.obs;

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
    refreshDevices();
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

  Future<void> refreshDevices() async {
    final capture = AudioCapture();
    final ok = await capture.hasPermission();
    if (!ok) return;
    final devices = await capture.listDevices();
    availableDevices.assignAll(devices);
    if (selectedDeviceId.value.isEmpty && devices.isNotEmpty) {
      selectedDeviceId(devices.first.id);
    }
  }

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

    await refreshDevices();

    final device = availableDevices.firstWhereOrNull(
      (d) => d.id == selectedDeviceId.value,
    );
    capture.selectDevice(device);

    _audioCapture = capture;
    isRecording(true);
    statusMessage('');

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
    statusMessage('');

    try {
      final audioBytes = await capture.stop();

      if (audioBytes.isEmpty) {
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
          ? '✅ تمت المعالجة'
          : '✅ Done');
    } catch (e) {
      debugPrint("Recording processing error: $e");
      statusMessage(isArabic.value
          ? '❌ فشلت المعالجة'
          : '❌ Processing failed');
    } finally {
      isProcessingRecording(false);
      capture.dispose();
      _audioCapture = null;
    }
  }

  // ---- File Upload ----

  Future<void> pickAudioFile() async {
    isPickingFile(true);
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: [
          'mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac', 'wma', 'amr',
          'mp4', 'mov', 'avi', 'mkv', 'webm',
        ],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        _selectedFileValue = result.files.first;
        hasSelectedFile(true);
        fileTranscriptionStatus('');
        isTranscribingFile(false);
      }
    } catch (e) {
      statusMessage('Error picking file: $e');
    } finally {
      isPickingFile(false);
    }
  }

  void clearSelectedFile() {
    _selectedFileValue = null;
    hasSelectedFile(false);
    fileTranscriptionStatus('');
    isTranscribingFile(false);
  }

  fp.PlatformFile? get selectedFile => _selectedFileValue;

  Future<void> transcribeSelectedFile() async {
    if (_selectedFileValue == null) return;
    if (effectiveApiKey.isEmpty) {
      showSettingsDialog();
      return;
    }

    final bytes = _selectedFileValue!.bytes;
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
        fileName: _selectedFileValue!.name,
        apiKey: effectiveApiKey,
        modelName: geminiModel.value,
        customInstructions: customInstructions.value,
        targetLanguage: isArabic.value ? 'ar' : 'en',
        onFallback: (_, __) {
          fileTranscriptionStatus(isArabic.value
              ? '⚠️ جاري التبديل لنموذج آخر...'
              : '⚠️ Switching to another model...');
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
        onFallback: (_, __) {
          statusMessage(isArabic.value
              ? '⚠️ جاري التبديل لنموذج آخر...'
              : '⚠️ Switching to another model...');
        },
      );

      textController.text = translatedText;
      textVersion(textVersion.value + 1);
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

  // ---- Summarize ----

  Future<void> summarizeSelectedText() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    if (effectiveApiKey.isEmpty) {
      showSettingsDialog();
      return;
    }

    isSummarizing(true);
    statusMessage(isArabic.value
        ? '🧠 جاري التلخيص...'
        : '🧠 Summarizing...');

    try {
      final summary = await TranscriptionService.summarizeText(
        text: text,
        apiKey: effectiveApiKey,
        modelName: geminiModel.value,
        customInstructions: customInstructions.value,
      );

      _appendText('\n--- ${isArabic.value ? "ملخص" : "Summary"} ---\n$summary');
      statusMessage(isArabic.value
          ? '✅ تم التلخيص بنجاح'
          : '✅ Summary added');
    } catch (e) {
      statusMessage(isArabic.value
          ? '❌ فشل التلخيص: $e'
          : '❌ Summarization failed: $e');
    } finally {
      isSummarizing(false);
    }
  }

  // ---- Action Helpers ----
  Future<void> copyText() async {
    if (textController.text.isNotEmpty) {
      try {
        await Clipboard.setData(ClipboardData(text: textController.text));
        statusMessage(isArabic.value
            ? '✅ تم نسخ النص بنجاح'
            : '✅ Text copied to clipboard');
        textVersion(textVersion.value + 1);
      } catch (e) {
        statusMessage(isArabic.value
            ? '❌ فشل النسخ: $e'
            : '❌ Copy failed: $e');
      }
    } else {
      statusMessage(isArabic.value
          ? '⚠️ لا يوجد نص لنسخه'
          : '⚠️ No text to copy');
    }
  }

  void clearText() {
    textController.clear();
    textVersion(textVersion.value + 1);
    statusMessage(isArabic.value ? '🗑️ تم مسح النص' : '🗑️ Text cleared');
  }

  Future<void> downloadTextFile() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final filename = 'transcription_$dateStr.txt';

    if (kIsWeb) {
      try {
        saveTextFileWeb(text, filename);
        statusMessage(isArabic.value
            ? '💾 تم تحميل الملف'
            : '💾 File downloaded');
      } catch (e) {
        statusMessage(isArabic.value
            ? '❌ فشل التحميل: $e'
            : '❌ Download failed: $e');
      }
    } else {
      try {
        final dir = Directory.systemTemp;
        final file = File('${dir.path}/$filename');
        await file.writeAsString(text);
        statusMessage(isArabic.value
            ? '💾 تم الحفظ في مجلد التنزيلات'
            : '💾 Saved successfully');
      } catch (e) {
        statusMessage(isArabic.value
            ? '❌ فشل الحفظ: $e'
            : '❌ Save failed: $e');
      }
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
    textVersion(textVersion.value + 1);
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

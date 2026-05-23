import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class TranscriptionService {
  /// Detect the correct MIME type based on file extension.
  static String getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp3':
        return 'audio/mp3';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/m4a';
      case 'ogg':
        return 'audio/ogg';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';
      case 'wma':
        return 'audio/x-ms-wma';
      case 'amr':
        return 'audio/amr';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      default:
        return 'audio/mp3'; // Fallback
    }
  }

  /// Transcribe an audio file using Google's Gemini models with auto-retry and model fallbacks.
  static Future<String> transcribeAudio({
    required Uint8List fileBytes,
    required String fileName,
    required String apiKey,
    String modelName = 'gemini-2.5-flash',
    String? customInstructions,
    String targetLanguage = 'auto', // 'ar', 'en', or 'auto'
    void Function(String fallbackModel, String error)? onFallback,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is empty. Please configure your Gemini API Key in settings.');
    }

    try {
      final mimeType = getMimeType(fileName);
      final audioPart = DataPart(mimeType, fileBytes);

      final isVideo = mimeType.startsWith('video/');
      String prompt = isVideo
          ? 'This is a video file. Extract the audio track and transcribe it exactly as spoken. '
          : 'Transcribe the audio exactly as spoken. ';
      prompt += 'Intelligently correct minor mispronunciations, '
          'slurred words, or unclear audio to their proper spelling. '
          'For example, if the speaker says "ello" in a context that clearly means "hello", write "hello". '
          'Do NOT add any conversational commentary, introductory text, or concluding notes. '
          'Return only the raw transcription text.';

      if (targetLanguage == 'ar') {
        prompt += ' The audio is in Arabic. Please transcribe it using proper Arabic grammar and punctuation, correcting any unclear words to their proper form.';
      } else if (targetLanguage == 'en') {
        prompt += ' The audio is in English. Please transcribe it using proper English spelling, capitalization, and punctuation, correcting unclear words to their proper form.';
      } else {
        prompt += ' Detect the language spoken (primarily Arabic or English) and transcribe it accurately in that language with correct punctuation, correcting unclear words.';
      }

      if (customInstructions != null && customInstructions.trim().isNotEmpty) {
        prompt += '\n\nAdditional user guidelines:\n$customInstructions';
      }

      final textPart = TextPart(prompt);

      final modelsToTry = _buildModelList(modelName);

      Object? lastError;

      for (int i = 0; i < modelsToTry.length; i++) {
        final currentModel = modelsToTry[i];
        try {
          final model = GenerativeModel(
            model: currentModel,
            apiKey: apiKey,
          );

          final response = await model.generateContent([
            Content.multi([audioPart, textPart]),
          ]);

          final transcription = response.text;
          if (transcription != null && transcription.isNotEmpty) {
            return transcription.trim();
          }
        } catch (e) {
          lastError = e;
          final errorStr = e.toString();
          
          // If we detect an invalid API key, throw immediately
          if (errorStr.contains('API_KEY_INVALID') || 
              errorStr.contains('API key not valid') || 
              errorStr.contains('invalid API key') ||
              errorStr.contains('403')) {
            throw Exception('Transcription failed due to API Key issue: $e');
          }
          
          // For any other error (503, 429, 404, 500, network, etc.), fall back to next model
          debugPrint('Model $currentModel failed with error: $errorStr. Cascading...');
          if (i < modelsToTry.length - 1) {
            final nextModel = modelsToTry[i + 1];
            onFallback?.call(nextModel, errorStr);
            // Wait 1.0 seconds before retrying with fallback model
            await Future.delayed(const Duration(milliseconds: 1000));
            continue;
          }
        }
      }

      throw Exception('Transcription failed: All fallback models are currently experiencing high demand or unsupported. Please try again in a few seconds. (Details: $lastError)');
    } catch (e) {
      throw Exception('Transcription failed: ${e.toString()}');
    }
  }

  /// Helper to translate text using Gemini API with auto-retry and model fallbacks.
  static Future<String> translateText({
    required String text,
    required String targetLanguage, // 'Arabic' or 'English'
    required String apiKey,
    String modelName = 'gemini-2.5-flash',
    void Function(String fallbackModel, String error)? onFallback,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is empty. Configure your Gemini API Key first.');
    }
    if (text.isEmpty) return '';

    try {
      final modelsToTry = _buildModelList(modelName);

      Object? lastError;

      for (int i = 0; i < modelsToTry.length; i++) {
        final currentModel = modelsToTry[i];
        try {
          final model = GenerativeModel(
            model: currentModel,
            apiKey: apiKey,
          );

          final response = await model.generateContent([
            Content.text(
              'Translate the following text into $targetLanguage. '
              'Provide ONLY the translated text without any explanation, markdown blocks, intro, or commentary.\n\nText:\n$text',
            ),
          ]);

          final translated = response.text;
          if (translated != null && translated.isNotEmpty) {
            return translated.trim();
          }
        } catch (e) {
          lastError = e;
          final errorStr = e.toString();
          
          // If we detect an invalid API key, throw immediately
          if (errorStr.contains('API_KEY_INVALID') || 
              errorStr.contains('API key not valid') || 
              errorStr.contains('invalid API key') ||
              errorStr.contains('403')) {
            throw Exception('Translation failed due to API Key issue: $e');
          }
          
          // For any other error (503, 429, 404, 500, network, etc.), fall back to next model
          debugPrint('Translation Model $currentModel failed with error: $errorStr. Cascading...');
          if (i < modelsToTry.length - 1) {
            final nextModel = modelsToTry[i + 1];
            onFallback?.call(nextModel, errorStr);
            await Future.delayed(const Duration(milliseconds: 1000));
            continue;
          }
        }
      }

      throw Exception('Translation failed: All fallback models are currently experiencing high demand or unsupported. Please try again. (Details: $lastError)');
    } catch (e) {
      throw Exception('Translation failed: ${e.toString()}');
    }
  }

  /// Summarize transcribed text.
  static Future<String> summarizeText({
    required String text,
    required String apiKey,
    String modelName = 'gemini-3.5-flash',
    String? customInstructions,
    void Function()? onFallback,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is empty.');
    }
    if (text.isEmpty) return '';

    final modelsToTry = _buildModelList(modelName);

    Object? lastError;

    for (int i = 0; i < modelsToTry.length; i++) {
      final currentModel = modelsToTry[i];
      try {
        final model = GenerativeModel(
          model: currentModel,
          apiKey: apiKey,
        );

        String prompt = 'Summarize the following text concisively. '
            'Capture the key points and main ideas. '
            'Return only the summary without any introductory or concluding commentary.';

        if (customInstructions != null && customInstructions.trim().isNotEmpty) {
          prompt += '\n\nAdditional guidelines:\n$customInstructions';
        }

        prompt += '\n\nText:\n$text';

        final response = await model.generateContent([Content.text(prompt)]);

        final summary = response.text;
        if (summary != null && summary.isNotEmpty) {
          return summary.trim();
        }
      } catch (e) {
        lastError = e;
        final errorStr = e.toString();

        if (errorStr.contains('API_KEY_INVALID') ||
            errorStr.contains('API key not valid') ||
            errorStr.contains('invalid API key') ||
            errorStr.contains('403')) {
          throw Exception('Summarization failed due to API Key issue: $e');
        }

        debugPrint('Summary Model $currentModel failed: $errorStr. Cascading...');
        if (i < modelsToTry.length - 1) {
          onFallback?.call();
          await Future.delayed(const Duration(milliseconds: 1000));
          continue;
        }
      }
    }

    throw Exception('Summarization failed. (Details: $lastError)');
  }

  static List<String> _buildModelList(String preferred) {
    const base = [
      'gemini-2.5-pro',
      'gemini-3.5-flash',
      'gemini-3.1-pro-preview',
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
    ];
    final result = <String>[];
    if (preferred.isNotEmpty) result.add(preferred);
    for (final m in base) {
      if (!result.contains(m)) result.add(m);
    }
    return result;
  }
}

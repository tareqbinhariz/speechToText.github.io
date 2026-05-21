import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_alsady_web/features/home/controllers/home_controller.dart';
import 'package:speech_to_text_alsady_web/features/home/widgets/audio_upload_tab.dart';
import 'package:speech_to_text_alsady_web/features/home/widgets/live_mic_tab.dart';
import 'package:speech_to_text_alsady_web/features/home/widgets/transcript_output.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final primaryBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
      final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
      final textSecondary = isDark ? Colors.white60 : Colors.black54;

      return Theme(
        data: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          fontFamily: 'NotoSansArabic',
          useMaterial3: true,
          scaffoldBackgroundColor: primaryBg,
          cardColor: cardBg,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.record_voice_over_rounded, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 8),
                Text(
                  MediaQuery.of(context).size.width < 600
                      ? (controller.isArabic.value ? 'أصوات' : 'Aswat')
                      : (controller.isArabic.value ? 'أصوات | النسخ الذكي' : 'Aswat | Smart Transcription'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: () {
                  controller.isDarkMode(!isDark);
                  controller.saveThemePreference(!isDark);
                },
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              ),
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: _showTipsDialog,
                tooltip: controller.isArabic.value ? 'مساعدة' : 'Help',
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () => controller.toggleLanguage(!controller.isArabic.value),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          MediaQuery.of(context).size.width < 500
                              ? (controller.isArabic.value ? 'AR 🇸🇦' : 'EN 🇺🇸')
                              : (controller.isArabic.value ? 'العربية 🇸🇦' : 'English 🇺🇸'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: controller.tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.mic_rounded),
                  text: controller.isArabic.value ? 'ميكروفون مباشر' : 'Live Mic',
                ),
                Tab(
                  icon: const Icon(Icons.video_file_rounded),
                  text: controller.isArabic.value ? 'رفع ملف' : 'Upload Media',
                ),
              ],
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: textSecondary,
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;
                final paddingVal = constraints.maxWidth < 600 ? 12.0 : 20.0;

                final captureCard = Card(
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16.0 : 24.0),
                    child: TabBarView(
                      controller: controller.tabController,
                      children: [
                        const LiveMicTab(),
                        const AudioUploadTab(),
                      ],
                    ),
                  ),
                );

                final outputCard = Card(
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16.0 : 24.0),
                    child: const TranscriptOutput(),
                  ),
                );

                return Padding(
                  padding: EdgeInsets.all(paddingVal),
                  child: isMobile
                      ? SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 480, child: captureCard),
                              const SizedBox(height: 16),
                              SizedBox(height: 520, child: outputCard),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 4, child: captureCard),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: outputCard),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  void _showTipsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(controller.isArabic.value ? '💡 نصائح للحصول على أدق نتائج' : '💡 Tips for Best Accuracy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.isArabic.value) ...[
                _tipItem('🎙️ تحدث بنبرة صوت طبيعية وبسرعة معتدلة'),
                _tipItem('🔇 تأكد من تسجيل الصوت في مكان هادئ وتجنب الضجيج'),
                _tipItem('🔑 التطبيق مهيأ تلقائياً للعمل مجاناً وبدون أي تكلفة إضافية'),
                _tipItem('📂 الملفات الكبيرة قد تستغرق وقتاً أطول للمعالجة والتحليل'),
                _tipItem('🔄 يمكنك استخدام ميزة الترجمة الفورية لترجمة النصوص المكتوبة'),
              ] else ...[
                _tipItem('🎙️ Speak at a natural volume and moderate pace'),
                _tipItem('🔇 Ensure quiet surroundings for minimum noise interference'),
                _tipItem('🔑 The app is pre-configured to work for free out-of-the-box'),
                _tipItem('📂 Large audio files might take slightly longer to process'),
                _tipItem('🔄 Leverage translation tools to instantly translate transcripts'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(controller.isArabic.value ? 'حسناً فهمت' : 'Got it'),
          ),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_alsady_web/features/home/controllers/home_controller.dart';
import 'package:speech_to_text_alsady_web/features/home/views/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(HomeController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aswat | Smart Speech to Text',
      theme: ThemeData(
        fontFamily: 'NotoSansArabic',
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const HomeView(),
    );
  }
}

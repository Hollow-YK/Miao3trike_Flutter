import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miao3trikeflutter/ui/screens/main_screen.dart';
import 'package:miao3trikeflutter/core/services/app_state.dart';
import 'package:miao3trikeflutter/core/services/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化主题管理器
  final themeManager = ThemeManager();
  await themeManager.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider.value(value: themeManager), // 使用 .value 传递已初始化的实例
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    
    return MaterialApp(
      title: 'Miao3trikeFlutter',
      theme: themeManager.generateLightTheme(themeManager.seedColor),
      darkTheme: themeManager.generateDarkTheme(themeManager.seedColor),
      themeMode: themeManager.getThemeModeFromString(themeManager.themeMode),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
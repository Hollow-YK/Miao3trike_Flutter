import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miao3trikeflutter/ui/screens/intro_screen.dart';
import 'package:miao3trikeflutter/ui/screens/function_screen.dart';
import 'package:miao3trikeflutter/ui/screens/settings_screen.dart';
import 'package:miao3trikeflutter/core/services/app_state.dart';
import 'package:miao3trikeflutter/core/services/theme_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // 默认选中功能页面
  final PageController _pageController = PageController(initialPage: 1);

  static final List<Widget> _pages = [
    const IntroScreen(),
    const FunctionScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void initState() {
    super.initState();
    // 初始化时刷新应用状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshAll();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final seedColor = themeManager.seedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 底部导航栏项目
    final List<BottomNavigationBarItem> bottomNavItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.info_outline),
        activeIcon: Icon(Icons.info, color: seedColor),
        label: '介绍',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.touch_app_outlined),
        activeIcon: Icon(Icons.touch_app, color: seedColor),
        label: '功能',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings, color: seedColor),
        label: '设置',
      ),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: bottomNavItems,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          selectedItemColor: seedColor,
          unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
    );
  }
}
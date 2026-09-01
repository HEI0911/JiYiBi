import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/category_provider.dart';
import 'services/storage_service.dart';
import 'services/transaction_provider.dart';
import 'pages/add_record_page.dart';
import 'pages/recent_records_page.dart';
import 'pages/summary_page.dart';

/// 应用入口
/// 启动后默认进入「记账页面」（AddRecordPage）
/// 底部 Tab 导航 3 页：记一笔（首页） / 最近记录 / 汇总排行
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  final transactions = TransactionProvider(storage);
  final categories = CategoryProvider(storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: categories),
        ChangeNotifierProvider.value(value: transactions),
      ],
      child: const JiYiBiApp(),
    ),
  );
}

class JiYiBiApp extends StatelessWidget {
  const JiYiBiApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    const seed = Color(0xFF4C6EF5);
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Smiley Sans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
      brightness: brightness,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF101218)
          : const Color(0xFFF8F9FE),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1A1D26) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // 统一字号语义层级：
      // display*  超大展示（记账页金额 42px）
      // headline* 标题级（汇总总额 32px / 页面大标题 28px）
      // titleMedium  行标题/金额 16px（记录行金额、日期时间块、区域小标题）
      // titleSmall    分类名 15px（记录行/排行分类名、日期时间 chips、分区标题）
      // bodyMedium    中等正文 14px（更多/收起、自定义按钮）
      // bodySmall     辅助说明 15px（备注时间、空状态、图例、排行百分比）
      // labelLarge    大按钮 16px（记一笔按钮）
      // labelMedium/labelSmall 12px（汇总时段标签、底部菜单栏）
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, letterSpacing: 1.5),
        displayMedium: TextStyle(fontSize: 45, letterSpacing: 1.5),
        displaySmall: TextStyle(fontSize: 42, letterSpacing: 1.5),
        headlineLarge: TextStyle(fontSize: 32, letterSpacing: 1.3),
        headlineMedium: TextStyle(fontSize: 32, letterSpacing: 1.3),
        headlineSmall: TextStyle(fontSize: 28, letterSpacing: 1.3),
        titleLarge: TextStyle(fontSize: 22, letterSpacing: 1.2),
        titleMedium: TextStyle(fontSize: 16, letterSpacing: 1.2),
        titleSmall: TextStyle(fontSize: 15, letterSpacing: 1.0),
        bodyLarge: TextStyle(fontSize: 16, letterSpacing: 1.2),
        bodyMedium: TextStyle(fontSize: 14, letterSpacing: 1.2),
        bodySmall: TextStyle(fontSize: 15, letterSpacing: 1.2),
        labelLarge: TextStyle(fontSize: 16, letterSpacing: 0.8),
        labelMedium: TextStyle(fontSize: 12, letterSpacing: 0.8),
        labelSmall: TextStyle(fontSize: 12, letterSpacing: 0.8),
      ),
      // 汇总时段 chips（labelMedium 12px，加大到 13 更醒目；
      // 必须显式补 fontFamily，否则 chipTheme 覆盖 TextStyle 时不会继承 theme 的 fontFamily，
      // 导致时段标签显示成系统默认字体）
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(
            fontFamily: 'Smiley Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: isDark
                ? const Color(0xFFC9CDD6)
                : const Color(0xFF3A3F4B)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      // 底部菜单栏（labelSmall 12px）：同样补 fontFamily，避免文字回落系统字体
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
              fontFamily: 'Smiley Sans',
              fontSize: 12,
              letterSpacing: 0.8,
              color: isDark
                  ? const Color(0xFFC9CDD6)
                  : const Color(0xFF3A3F4B)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记一笔',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      locale: const Locale('zh', 'CN'),
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  /// 默认显示第 0 页 = 记账页面
  int _index = 0;

  final List<Widget> _pages = const [
    AddRecordPage(),
    RecentRecordsPage(),
    SummaryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_rounded),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: '记一笔',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            selectedIcon: Icon(Icons.receipt_rounded),
            label: '最近',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: '汇总',
          ),
        ],
      ),
    );
  }
}

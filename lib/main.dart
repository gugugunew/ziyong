import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'iphone_frame.dart';

/// 是否在 Chrome 预览时套 iPhone 16 Pro 真机外壳。
/// true  = `flutter run -d chrome` 直接看到真机框；
/// false = 用项目原有 iphone16_preview.html + localhost:8090 流程（避免双重套框）。
const bool kUseDeviceFrame = true;

/// 全局 Navigator key：确保返回按钮精确命中根 Navigator，排除任何嵌套歧义。
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const MelodyApp());
}

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

final themeController = ThemeController();

class MelodyApp extends StatelessWidget {
  const MelodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final app = MaterialApp(
          title: 'Melody',
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          themeMode: themeController.mode,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          home: const RootPage(),
        );
        return kUseDeviceFrame
            ? IPhone16ProFrame(isDark: themeController.isDark, child: app)
            : app;
      },
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  【永久锁定 · 全局苹果字体栈】                                        ║
  // ║  Web 平台无法授权 SF Pro 字体文件，统一用系统 UI 字体栈：            ║
  // ║  macOS/iOS → 真 SF Pro；Windows → Segoe UI（同族最接近苹果观感）      ║
  // ║  所有文字自动继承，禁止在各处再手写 fontFamily                       ║
  // ╚══════════════════════════════════════════════════════════════════╝
  static const String _appleFont =
      '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", "Segoe UI", Roboto, sans-serif';
  static const List<String> _appleFontFallback = [
    'SF Pro Display',
    'SF Pro Text',
    '.SF Pro Display',
    '.SF NS Display',
    'Helvetica Neue',
    'Segoe UI',
    'Roboto',
  ];

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  【Apple 循环色块 · 板块背景】                                        ║
  // ║  每个大区块都是顶部浅、底部深的渐变；相邻板块交界处自然形成          ║
  // ║  "上深下浅" 的跳变（上面板块底部深，下面板块顶部浅）。               ║
  // ╚══════════════════════════════════════════════════════════════════╝
  static const Color _blockTopLight = Color(0xFFFEFEFE);
  static const Color _blockBottomLight = Color(0xFFE8E8E8);
  static const Color _blockTopDark = Color(0xFF1C1C1E);
  static const Color _blockBottomDark = Color(0xFF010101);

  // 返回板块背景：亮色/暗色均用渐变，相邻板块自然过渡
  static BoxDecoration _panelDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [_blockTopDark, _blockBottomDark]
            : [_blockTopLight, _blockBottomLight],
      ),
    );
  }

  ThemeData _lightTheme() {
    const bg = Color(0xFFFFFFFF); // 锁定背景色：白天 #FFFFFF
    const surface = Color(0xFFF2F2F7);
    const textPrimary = Color(0xFF1C1C1E);
    const textSecondary = Color(0x991C1C1E);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _appleFont,
      fontFamilyFallback: _appleFontFallback,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007AFF),
        secondary: Color(0xFFFF375F),
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(fontSize: 15, color: textSecondary),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
      ),
    );
  }

  ThemeData _darkTheme() {
    const bg = Color(0xFF010101); // 锁定背景色：黑夜 #010101
    const surface = Color(0xFF1C1C1E);
    const textPrimary = Color(0xFFF5F5F7);
    const textSecondary = Color(0x99F5F5F7);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _appleFont,
      fontFamilyFallback: _appleFontFallback,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF007AFF),
        secondary: Color(0xFFFF375F),
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(fontSize: 15, color: textSecondary),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> with TickerProviderStateMixin {
  int _index = 0;
  final ScrollController _homeScroll = ScrollController();

  final _pages = const [
    HomePage(key: ValueKey('home')),
    LibraryPage(key: ValueKey('library')),
    BookstorePage(key: ValueKey('bookstore')),
    FavoritesPage(key: ValueKey('favorites')),
    LibraryPage(key: ValueKey('theme_placeholder')),
  ];

  void _onTabChanged(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  void dispose() {
    _homeScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      extendBody: true,
      backgroundColor: bg,
      body: Stack(
        children: [
          // 页面内容：沉浸式，从顶部开始（灵动岛下方），无顶部导航栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _index == 0
                  ? HomePage(
                      key: const ValueKey('home'),
                      scrollController: _homeScroll,
                    )
                  : _pages[_index],
            ),
          ),
          // 底部导航栏（浮动圆角毛玻璃，Apple Music 风格）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassTabBar(index: _index, onChanged: _onTabChanged),
          ),
        ],
      ),
    );
  }
}

class _HtmlNavTab extends StatelessWidget {
  final bool active;
  final String glyph;
  final String label;
  final bool isTheme;
  final VoidCallback onTap;
  const _HtmlNavTab({
    required this.active,
    required this.glyph,
    required this.label,
    required this.isTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF375F);
    final inactiveColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.45);
    final fgColor = active ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isTheme) {
            themeController.toggle();
          } else {
            onTap();
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              glyph,
              style: TextStyle(fontSize: 25, color: fgColor, height: 1),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: fgColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════╗
// ║  【底部导航栏 · 浮动圆角毛玻璃栏】                                    ║
// ║  Apple Music 风格浮动椭圆导航栏：blur 20、圆角 35、1px 边框。       ║
// ║  常驻显示，浮在屏幕底部。                                            ║
// ╚══════════════════════════════════════════════════════════════════╝
class GlassTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const GlassTabBar({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const barHeight = 78.0;
    const barRadius = 35.0;
    const blurSigma = 20.0;
    final tabs = [
      (glyph: '⌂', label: 'Listen'),
      (glyph: '◯', label: 'Explore'),
      (glyph: '▣', label: 'Learn'),
      (glyph: '♡', label: 'Favorites'),
      (glyph: '☾', label: 'Theme'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Stack(
        children: [
          // 底层：高斯模糊背景。比上层稍大一圈，避免 ClipRRect 裁剪 BackdropFilter
          // 时边缘采样不到像素而产生的暗边/阴影。
          Positioned(
            left: -4,
            right: -4,
            top: -4,
            bottom: -4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(barRadius + 4),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // 上层：玻璃面板（边框、底色、高光、内阴影、标签）
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              // 玻璃底色：提高不透明度，保证文字可读（暗色更实、亮色半透）
              color: isDark
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(barRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // 顶部高光描边（玻璃上沿 specular highlight）
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: isDark ? 0.35 : 0.7),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // 顶部内阴影（玻璃厚度）
                Container(
                  height: 0.5,
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                ),
                // 标签行
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (int i = 0; i < tabs.length; i++)
                        _HtmlNavTab(
                          active: index == i,
                          glyph: tabs[i].glyph,
                          label: tabs[i].label,
                          isTheme: i == 4,
                          onTap: () => onChanged(i),
                        ),
                    ],
                  ),
                ),
                // 底部内阴影（玻璃下沿厚度）
                Container(
                  height: 0.5,
                  color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 旧版底部导航栏（升级液态玻璃之前的样式）：纯色磨砂 + 1px 边框，无高光/内阴影
class LegacyGlassTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const LegacyGlassTabBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const barHeight = 78.0;
    const barRadius = 35.0;
    const blurSigma = 20.0;
    final blurColor = isDark
        ? const Color(0xFF141414).withValues(alpha: 0.65)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.65);
    final borderColor = Colors.white.withValues(alpha: 0.3);
    final tabs = [
      (glyph: '⌂', label: 'Listen'),
      (glyph: '◯', label: 'Explore'),
      (glyph: '▣', label: 'Learn'),
      (glyph: '♡', label: 'Favorites'),
      (glyph: '☾', label: 'Theme'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(barRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: blurColor,
              borderRadius: BorderRadius.circular(barRadius),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < tabs.length; i++)
                  _HtmlNavTab(
                    active: index == i,
                    glyph: tabs[i].glyph,
                    label: tabs[i].label,
                    isTheme: i == 4,
                    onTap: () => onChanged(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TestThemeButton extends StatefulWidget {
  final bool isDark;
  const TestThemeButton({super.key, required this.isDark});

  @override
  State<TestThemeButton> createState() => _TestThemeButtonState();
}

class _TestThemeButtonState extends State<TestThemeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.87), weight: 27),
    TweenSequenceItem(tween: Tween(begin: 0.87, end: 1.10), weight: 23),
    TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward(from: 0);
    themeController.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.7);
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, a) =>
                  RotationTransition(turns: a, child: child),
              child: Icon(
                widget.isDark ? Icons.sunny : Icons.nightlight_round,
                key: ValueKey(widget.isDark),
                color: color,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 分区按钮：与页面背景同色的胶囊，靠柔和投影从内容中浮出，保证可读性
// 尺寸对齐底部 Stepo 标签按钮（高 = barHeight*0.86、左右内边距 18），字号为 Stepo 文字 13pt 的 0.68 倍
// 按压回弹遵循 apple-motion-clone 规范：0.87 → 1.10 → settle，600ms 弹簧
class _CategoryButton extends StatefulWidget {
  final bool isDark;
  final double barHeight;
  const _CategoryButton({required this.isDark, required this.barHeight});

  @override
  State<_CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<_CategoryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.87), weight: 27),
    TweenSequenceItem(tween: Tween(begin: 0.87, end: 1.10), weight: 23),
    TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final h = widget.barHeight * 0.86;
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _ctrl.forward(from: 0),
          child: Container(
            height: h,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(999),
              // glassmorphism：玻璃元素需细边框 + 足够对比
              border: Border.all(
                color: fg.withValues(alpha: widget.isDark ? 0.18 : 0.10),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isDark
                      ? Colors.black.withValues(alpha: 0.40)
                      : Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '分区',
              style: TextStyle(
                fontSize: 13 * 0.68,
                fontWeight: FontWeight.w600,
                // glassmorphism 对比规则：文字不完全同背景，加轻微透明度
                color: fg.withValues(alpha: 0.85),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final ScrollController? scrollController;
  const HomePage({super.key, this.scrollController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Stepo 标题随滚动柔和淡出（1=完全显示，0=完全消失）
  double _titleOpacity = 1.0;
  // 随滚动轻微上移 + 缩小，让消失更柔和不生硬
  double _titleShift = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    _syncInitial();
  }

  void _syncInitial() {
    final c = widget.scrollController;
    if (c != null && c.hasClients) _applyScroll(c.offset);
  }

  void _onScroll() {
    final c = widget.scrollController;
    if (c == null || !c.hasClients) return;
    _applyScroll(c.offset);
  }

  void _applyScroll(double offset) {
    // 滚动 0~24px 内，标题 opacity 从 1 平滑降到 0（轻微滑动即柔和消失）
    final t = (offset / 24.0).clamp(0.0, 1.0);
    final op = 1.0 - t;
    // 同步轻微上移（最多 8px）与缩小（最小 0.92），强化柔和过渡
    final shift = -8.0 * t;
    if ((op - _titleOpacity).abs() > 0.005 ||
        (shift - _titleShift).abs() > 0.01) {
      setState(() {
        _titleOpacity = op;
        _titleShift = shift;
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
      _syncInitial();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

    // ╔══════════════════════════════════════════════════════════════════╗
    // ║  顶部简洁大标题                                                       ║
    // ║  Stepo 固定大标题，无折叠、无滚动渐隐。                              ║
    // ╚══════════════════════════════════════════════════════════════════╝
    final statusHeight = MediaQuery.of(context).viewPadding.top;
    const titleSize = 30.0;
    // 标题放在状态栏下方 12pt，留出灵动岛/刘海区域；
    // 内容从 headerHeight 之后开始，确保所有内容都在状态栏下方。
    const titleGap = 12.0;
    final titleTop = statusHeight + titleGap;
    final headerHeight = titleTop + titleSize + 10.0;
    // 顶部边缘柔化遮罩：覆盖状态栏区域，往下立刻清晰
    final edgeFadeHeight = titleTop;
    return Stack(
      children: [
        CustomScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              leading: const SizedBox.shrink(),
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              expandedHeight: headerHeight,
              flexibleSpace: const SizedBox.shrink(),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // ── 板块 1：精选合集（标签栏 + FEATURED COLLECTION 标题 + 轮播）──
                  const _FeaturedCollectionBlock(),
                  // ── 板块 2：类别（单词/句子/短文/影视/图书/AI，卡片板块）──
                  const _CategoryCardsSection(),
                  // ── 板块 3：热门新书（卡片板块）──
                  _TintedSection(
                    segment: 2,
                    child: _BookSection(
                      title: '热门新书',
                      showAll: true,
                      subtitle: 'Recently released and notable books.',
                      count: 7,
                    ),
                  ),
                  // ── 板块 4：新增 audiobooks（卡片板块）──
                  _TintedSection(
                    segment: 3,
                    child: _BookSection(
                      title: '新增 audiobooks',
                      subtitle: 'Listen to the latest releases.',
                      count: 6,
                    ),
                  ),
                  // ── 板块 5：主编推荐（卡片板块）──
                  _TintedSection(
                    segment: 4,
                    child: _BookSection(
                      title: '主编推荐',
                      subtitle: 'Curated picks from our editors.',
                      count: 6,
                    ),
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ],
        ),
        // Stepo 标题：固定在顶层，随滚动柔和淡出（上移+缩小+透明），不被 SliverAppBar 裁剪
        Positioned(
          left: 20,
          top: titleTop,
          child: Transform.translate(
            offset: Offset(0, _titleShift),
            child: Opacity(
              opacity: _titleOpacity,
              child: Transform.scale(
                scale: 0.92 + 0.08 * _titleOpacity,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Stepo',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        // 顶部遮罩：单段渐变，顶部浓度大、往下立刻归零
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: edgeFadeHeight,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgBase.withValues(alpha: 0.55), // 顶部浓度大，绝不泛白光
                    bgBase.withValues(alpha: 0.0), // 立刻归零，完全清晰
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 横向滚动分类标签栏（图标 + 文字胶囊，可左右滑动）
class _CategoryTagsBar extends StatefulWidget {
  const _CategoryTagsBar();

  @override
  State<_CategoryTagsBar> createState() => _CategoryTagsBarState();
}

class _CategoryTagsBarState extends State<_CategoryTagsBar> {
  // 独立滚动控制器，避免被父级 CustomScrollView 的纵向手势吞掉
  late final ScrollController _hScroll;

  @override
  void initState() {
    super.initState();
    _hScroll = ScrollController();
  }

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  final List<(String icon, String label)> _tags = const [
    ('assets/icons/recommend.svg', '推荐'),
    ('assets/icons/zero.svg', '零基础'),
    ('assets/icons/beginner.svg', '入门'),
    ('assets/icons/elementary.svg', '初级'),
    ('assets/icons/intermediate.svg', '中级'),
    ('assets/icons/upper_intermediate.svg', '中高级'),
    ('assets/icons/advanced.svg', '高级'),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 40,
      // Web 上鼠标拖拽横向列表必须显式把 mouse 加入 dragDevices，否则手势被父级吞掉
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            ui.PointerDeviceKind.touch,
            ui.PointerDeviceKind.mouse,
            ui.PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          controller: _hScroll,
          primary: false,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _tags.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final tag = _tags[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: textColor.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(tag.$1, width: 18, height: 18),
                  const SizedBox(width: 6),
                  Text(
                    tag.$2,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// 连续色块容器：按 segment 取相邻同色渐变，承载某区块内容
// segment 0..4 对应 5 段衔接：page→blue→purple→orange→green→page
class _TintedSection extends StatelessWidget {
  final int segment;
  final Widget child;
  const _TintedSection({required this.segment, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: MelodyApp._panelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 36),
        child: child,
      ),
    );
  }
}

// Featured Collection 板块：标签栏 + 标题 + 轮播，作为一个完整板块
// 背景：纯色 + 底部光影边
class _FeaturedCollectionBlock extends StatelessWidget {
  const _FeaturedCollectionBlock();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      // 视听英语板块在暗色下纯黑，不要渐变
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF010101) : null,
        gradient: isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [MelodyApp._blockTopLight, MelodyApp._blockBottomLight],
              ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 板块顶部：横向滑动分级标签栏
          Padding(padding: EdgeInsets.only(top: 4), child: _CategoryTagsBar()),
          SizedBox(height: 18),
          // 轮播（含 FEATURED COLLECTION 标题）
          _CategoryBanner(),
        ],
      ),
    );
  }
}

// 词书板块：2 行 × 4 列横向滚动网格，书封统一尺寸、底部带阴影、不循环
class _CategoryCardsSection extends StatelessWidget {
  const _CategoryCardsSection();

  static const List<_WordBook> _books = [
    _WordBook(
      '小学英语大纲词汇',
      'assets/images/xiaoxue_english_vocabulary.jpg',
      xiaoxueWords,
    ),
    _WordBook('词书·自然拼读', 'assets/images/cishu_1.png', []),
    _WordBook('词书·情景对话', 'assets/images/cishu_2.png', []),
    _WordBook('词书·看图识词', 'assets/images/cishu_3.png', []),
    _WordBook('词书·高频词', 'assets/images/cishu_4.png', []),
    _WordBook('词书·主题分类', 'assets/images/cishu_5.png', []),
    _WordBook('词书·词汇进阶', 'assets/images/cishu_6.png', []),
    _WordBook('词书·趣味记忆', 'assets/images/cishu_7.png', []),
    _WordBook('词书·考前冲刺', 'assets/images/cishu_8.png', []),
  ];

  // 统一书封尺寸（调小整体高度）
  static const double _cardW = 104.0;
  static const double _cardH = 138.0;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 16),
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        width: double.infinity,
        decoration: MelodyApp._panelDecoration(context),
        padding: const EdgeInsets.only(top: 28, bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '单词',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: textColor.withValues(alpha: 0.35),
                    size: 22,
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '显示全部',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: textColor.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '选择你记忆的单词本',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              // 两行高度 + 行间距 + 上下内边距
              height: _cardH * 2 + 12 + 16,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    ui.PointerDeviceKind.touch,
                    ui.PointerDeviceKind.mouse,
                    ui.PointerDeviceKind.trackpad,
                  },
                ),
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  // ClampingScrollPhysics：到边界停止，不循环
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: _cardH / _cardW, // 竖向书封比例
                  ),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return _CategoryBookCover(
                      book: book,
                      onTap: (rect) async {
                        // 进入词表页期间暂停主页 Banner 自动滚动（性能 + 视觉）
                        _bannerAuto.pause();
                        // 隐藏 grid 里被点的静态封面：由飞行层「原图」副本接管，
                        // 避免静态图 + 副本同时显示（重影）。
                        _flyingCoverBook.value = book;
                        // 只传源卡片矩形。终点矩形**不在这里算** ——
                        // 这里拿到的 MediaQuery.size 可能是整个浏览器窗口的尺寸
                        // （iPhone 外壳下 MaterialApp 继承的 MediaQuery 不可靠），
                        // 算出来的终点会飞到屏幕外面。终点由页面自身布局决定，
                        // 路由层则用 LayoutBuilder 拿真实尺寸来缩放。
                        await Navigator.of(context)
                            .push(_appleOpenRoute(book, rect));
                        // pop（返回动画播完）后恢复静态封面 + Banner
                        _flyingCoverBook.value = null;
                        _bannerAuto.resume();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 单个词书封面：固定 104×138，完整展示图片，底部带柔和书影，可点击进入词表
class _CategoryBookCover extends StatelessWidget {
  final _WordBook book;
  final ValueChanged<Rect> onTap;
  final GlobalKey _key = GlobalKey();

  _CategoryBookCover({required this.book, required this.onTap});

  /// 取当前封面的真实坐标，作为打开路由的「生长起点」。
  ///
  /// 关键：路由的飞行层是画在 `Overlay` 里的，而 Overlay 被 iPhone 外壳的
  /// 边框（bezel）与居中偏移过，它有自己的局部坐标系。若直接用
  /// `localToGlobal`（相对整个窗口）当 Overlay 内坐标，封面会整体偏一段，
  /// 看起来就是「图片出现在别的地方」。必须转成 Overlay 局部坐标。
  Rect _originRect(BuildContext context) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Rect.zero;
    final globalTopLeft = box.localToGlobal(Offset.zero);

    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      final overlayBox = overlay.context.findRenderObject() as RenderBox?;
      if (overlayBox != null && overlayBox.attached) {
        return overlayBox.globalToLocal(globalTopLeft) & box.size;
      }
    } catch (_) {
      // 取不到 Overlay（极少见）时退回全局坐标
    }
    return globalTopLeft & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(_originRect(context)),
      child: Container(
        key: _key,
        width: _CategoryCardsSection._cardW,
        height: _CategoryCardsSection._cardH,
        alignment: Alignment.center,
        // 这本书正在飞行时，静态封面隐藏（Opacity 0，布局占位保持，grid 不跳），
        // 由飞行层副本接管；返回动画播完后恢复。Apple 里被点的格子也是腾空的。
        child: ValueListenableBuilder<_WordBook?>(
          valueListenable: _flyingCoverBook,
          builder: (context, flying, child) => Opacity(
            opacity: identical(flying, book) ? 0.0 : 1.0,
            child: child,
          ),
          // 书封图片 + Apple Books 风格下阴影：直接把阴影画在书的圆角容器上，
          // 而不是单独加一个扁阴影层，这样形状更自然、更贴近 iPhone 观感。
          child: Container(
            width: _CategoryCardsSection._cardW,
            height: _CategoryCardsSection._cardH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                // Apple Books 风格：极淡、极柔、范围大的环境阴影，
                // 让书像浮在白色桌面上，而不是底部一条黑边。
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 48,
                  spreadRadius: -6,
                  offset: const Offset(0, 22),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 26,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                book.cover,
                fit: BoxFit.contain,
                cacheWidth: 320,
                frameBuilder: (context, child, frame, sync) {
                  if (sync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 展开几何曲线。
///
/// 注意：这里**不能**用 `Cubic(0.32, 0.72, 0, 1)` 那种严重前置的曲线 ——
/// 它会在 30% 的时间里跑完约 77% 的进度，卡片一上来就变得又宽又实，
/// 与 Apple「先小、后绽开」的观感完全相反（就是之前"太宽了"的根因）。
///
/// 同理，几何进度算出来之后**不要再叠一层 easeOutCubic**：
/// 几何只用一条曲线当「时钟」，尺寸线性跟随它（不再叠加第二层前置曲线）。
/// 这条曲线直接按用户逐帧实测数据拟合（见 _MeasuredOpenCurve）。
const Curve _kOpenCurve = _MeasuredOpenCurve();

/// 打开动画进度曲线：严格按用户逐帧实测数据拟合。
/// 数据来自 iPhone 16 Pro 录屏（00:01.51 → 00:01.91，满屏 0.40s）：
/// 卡片宽 140 → 349 线性映射为 pw = (w−140)/209，记录 pw 随时间的轨迹。
/// _tau 是**归一化动画进度**(0..1)，满屏(pw=1.0)落在 τ=0.74。
/// 真实总时长由 kOpenDurationMs 决定，改它只是整体拉伸时间、不改变曲线形状。
class _MeasuredOpenCurve extends Curve {
  const _MeasuredOpenCurve();

  // τ = 归一化动画进度(0..1)，由 _tau 表直接给出
  static const List<double> _tau = <double>[
    0.00, 0.08, 0.12, 0.16, 0.18, 0.22, 0.24, 0.28, 0.32, 0.36,
    0.40, 0.42, 0.46, 0.48, 0.56, 0.58, 0.62, 0.66, 0.70, 0.74,
  ];
  static const List<double> _pw = <double>[
    0.000, 0.225, 0.325, 0.450, 0.545, 0.637, 0.704, 0.767, 0.851, 0.880,
    0.890, 0.928, 0.942, 0.957, 0.971, 0.976, 0.986, 0.990, 0.990, 1.000,
  ];

  @override
  double transform(double t) {
    if (t <= 0.0) return 0.0;
    if (t >= 0.74) return 1.0;
    for (int i = 0; i < _tau.length - 1; i++) {
      final t0 = _tau[i];
      final t1 = _tau[i + 1];
      if (t >= t0 && t <= t1) {
        final f = (t - t0) / (t1 - t0);
        return _pw[i] + (_pw[i + 1] - _pw[i]) * f;
      }
    }
    return 1.0;
  }
}

/// 「复制的图片」出现的**宽度进度**（Apple Music 120Hz 逐帧实测）：
/// 卡片宽 208 那一帧复制图首次出现 → pw = (208-140)/(349-140) ≈ 0.3254。
/// 宽度进度 pw = (卡片宽 − 源卡宽) / (满屏宽 − 源卡宽)，与动画进度 g 同义。
const double kCopyAppearProgress = 0.3254;
/// 复制图淡入的提前量（占整段动画的比例）：复制图在触发点之前就开始浮现，
/// 到触发点时原图「稍比复制图更清晰」，随后原图慢慢退到 0。
/// 调大 = 复制图更早更实；调小 = 触发时复制图更淡。
const double kCopyFadeLead = 0.28;

/// 卡片**高度进度**锚点表（自变量 = 宽度进度 pw = g，17 个均匀网格点，线性插值）。
///
/// Apple Music 120Hz 逐帧实测（卡片 140×140 → 349×760）：
///   187/282 208/340 234/400 254/454 273/508 287/551 300/595 318/640 …
///   340/724 343/736 346/747 349/760
/// 幂律 h=w^p 拟合最大误差 47px（p 前段≈1.0、后段≈1.4，不是常数），
/// 故改为锚点插值：最大误差 5px、RMS 1.7px（<1%）。高度进度整体落后于
/// 宽度进度 → 卡片先变宽、再慢慢变高，是自然的「长大」过程。
const List<double> kCardHeightPhAnchors = <double>[
  0.0000, 0.0637, 0.1273, 0.1910, 0.2524, 0.3106, 0.3612, 0.4098, 0.4651,
  0.5228, 0.5827, 0.6465, 0.7161, 0.7734, 0.8366, 0.9136, 1.0000,
];
/// 卡片透明度：直接跟随卡片宽度进度（pw = g）。
///   起点 kCardOpacityStart（卡片宽140）→ 满屏(pw=1,卡片宽349) 1.0，线性映射，
///   与卡片宽曲线同一时钟、同形（前段随卡片宽暴涨）。满屏必为 1.0（实底）。
const double kCardOpacityStart = 0.85;

/// 透明度前导斜坡：开场 0→kCardOpacityRampMs 毫秒内，透明度从
/// kCardOpacityRampStart 快速升到 kCardOpacityRampEnd（=kCardOpacityStart），
/// 之后继续走上面的「跟随卡片宽度」映射。
const double kCardOpacityRampStart = 0.20;
const double kCardOpacityRampMs = 50.0;

/// 原图（被点那张封面）的「抬起 + 缩小退场」——Apple Music 120Hz 逐帧实测：
/// 静态宽 140 → 抬起峰值 145（×1.0357），向上垂直位移 25px（= 0.1786 × 图高）。
/// 展开段（卡片一出现的那一刻）原图就钉在卡片左上角，从峰值开始随卡片宽进度 g
/// 平稳持续缩小，到 kSrcGoneProgress（原图不可见）时收到 0，与淡出同节奏收尾。
const double kSrcLiftPeakScale = 1.0357;
const double kSrcLiftShiftY = 0.1786;
// 缩小曲线指数：1.0 = 线性（匀速慢慢缩）；>1 早期更慢、收尾更快（更"舒缓"）。
const double kSrcShrinkPow = 1.0;
/// 原图尺寸缩小 / 复制图交叠窗口收尾的宽度进度（实测 pw=0.703，卡片 287）。
/// 注意：透明度比它更早归零（见 kSrcFadeEnd），尺寸与复制图仍收到这里。
const double kSrcGoneProgress = 0.703;
/// 原图透明度归零（完全透明）对应的卡片宽进度：用户指定 原图 到 00:01.62
/// （卡273，pw=0.636）即完全透明——比尺寸/复制图终点更早收尾。
const double kSrcFadeEnd = 0.636;
/// 原图淡出缓动指数：>1 = 前期更实（慢）、临近终点才快速变透（「卡片越大越透、慢慢变淡」）。
/// 2.0 ≈ 二次 ease-in；越大前期越实、收尾越陡。
const double kSrcFadePow = 2.0;

/// 动画时长（毫秒）。
///
/// Apple 120Hz 实测：从点击（1.51s）到视觉上展开到位（1.91s）≈ 0.4s。
/// 返回动画一般比打开快，按 0.7 倍取 280ms。
// ⚠️ 测试减速中：原「当前速度」= 500ms，用户验证完说「恢复到现在的速度」即改回 500。
const int kOpenDurationMs = 500;
const int kCloseDurationMs = 500;
/// 抬升阶段时长（真实毫秒）：封面先从网格原位抬起/放大，之后卡片才展开。
/// 抬升段时长 = iPhone 录屏实测「抬起」帧：00:01.51→00:01.53 = 20ms（与总时长 400ms 解耦，单独定）。
/// 可单独调，不影响曲线形状。
const double kLiftDurationMs = 20.0;

/// 锚点表线性插值：`anchors[i]` 对应进度 `i / (n-1)`，x ∈ [0,1]。
double _lerpAnchors(List<double> anchors, double x) {
  final n = anchors.length - 1;
  if (x <= 0) return anchors.first;
  if (x >= 1) return anchors.last;
  final fx = x * n;
  final i = fx.floor();
  if (i >= n) return anchors.last;
  final f = fx - i;
  return anchors[i] + (anchors[i + 1] - anchors[i]) * f;
}

/// Apple Music 风格打开动画路由：用 `PopupRoute` 替代 `PageRouteBuilder(opaque:false)`，
/// 既保留「旧首页可见 + 卡片扩展 + 封面飞行」效果，又避免 web 下自定义 page route 的 pop 失灵。
class _AppleOpenRoute<T> extends PopupRoute<T> {
  final _WordBook book;
  final Rect originRect;

  _AppleOpenRoute({required this.book, required this.originRect});

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  /// 必须为 false：否则 Navigator 不会绘制下层路由，旧首页就看不见了。
  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration =>
      const Duration(milliseconds: kOpenDurationMs);

  @override
  Duration get reverseTransitionDuration =>
      const Duration(milliseconds: kCloseDurationMs);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // 用与 buildTransitions 相同的 curve 驱动，保证两边读到的进度值一致；
    // 再用 AnimatedBuilder 包一层，让页面随动画逐帧重建，
    // 否则 _AlbumHeader 里读到的 reveal.value 永远是首帧的值，封面交接不会发生。
    final curved = CurvedAnimation(parent: animation, curve: _kOpenCurve);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => _WordListPage(book: book, reveal: curved),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 关键：用 LayoutBuilder 拿**真实布局尺寸**，不要用 MediaQuery.of(context).size。
    // iPhone 外壳下 MaterialApp 继承的 MediaQuery 可能是整个浏览器窗口的尺寸，
    // 用它当满屏尺寸会让 100% 时的卡片比可见区域大得多 → 直接飞到屏幕外面，
    // 而 g=1 时又切成真实的 child → 就是你看到的那一下「跳变」。
    return LayoutBuilder(
      builder: (context, c) {
        final mqSize = MediaQuery.of(context).size;
        final size = Size(
          c.maxWidth.isFinite ? c.maxWidth : mqSize.width,
          c.maxHeight.isFinite ? c.maxHeight : mqSize.height,
        );
        // 只依赖尺寸、不依赖 g 的量全部提到逐帧 builder 外面。
        // 触发点 = 复制图首次出现的宽度进度（Apple 实测，直接取常量）。
        const double triggerG = kCopyAppearProgress;
        // 复制图淡入起点（比触发点提前 kCopyFadeLead）/ 到原图不可见为止的交叠区间。
        final fadeStart = (triggerG - kCopyFadeLead).clamp(0.0, 1.0);
        final fadeSpan = (kSrcGoneProgress - fadeStart).clamp(0.05, 1.0);

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            // ---------- 时间轴：抬升段 → 展开段（两段共用一个控制器）----------
            // tMs       = 真实毫秒（随 animation.value 线性 0→1）
            // liftRaw   = 抬升进度 0→1（0→kLiftDurationMs）
            // expRaw    = 展开进度 0→1（kLiftDurationMs→结束），再经 _kOpenCurve 塑形得 g
            final tMs = animation.value * kOpenDurationMs;
            final liftRaw = (tMs / kLiftDurationMs).clamp(0.0, 1.0);
            final liftEase = Curves.easeOut.transform(liftRaw);
            final expRaw = (((tMs - kLiftDurationMs) /
                        (kOpenDurationMs - kLiftDurationMs)))
                    .clamp(0.0, 1.0);
            final g = _kOpenCurve.transform(expRaw);

            // 动画结束后直接把页面本体交出去：
            // 省掉 BackdropFilter 模糊层，否则列表滚动时一直挂着全屏模糊，掉帧。
            if (g >= 1.0 && liftRaw >= 1.0) return child;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final surface = isDark ? const Color(0xFF1C1C1E) : Colors.white;
            // 压暗层调浅，让旧首页能透出来（深色主题下尤其明显）
            final dimColor = isDark
                ? const Color(0xFF000000).withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.35);

            // 抬起位移量（与 Apple 实测一致：上移 25px）
            final liftY = kSrcLiftShiftY * originRect.height;

            // ---------- ① 卡片几何：源卡片 → 满屏 ----------
            // 起点（g=0）已带抬起偏移：卡片左上角 = 抬起后的封面左上角，
            // 这样「抬升段结束」与「展开段开始」同一位置，过渡无缝。
            // 宽进度 pw = g 线性；高进度 ph 按 Apple 实测锚点表插值
            // （高度进度落后于宽度进度 → 先变宽、再变高）。全程连续，绝不跳变。
            final pw = g;
            final ph = _lerpAnchors(kCardHeightPhAnchors, pw);
            final cardRect = Rect.fromLTWH(
              originRect.left * (1 - pw),
              (originRect.top - liftY) * (1 - pw),
              originRect.width + (size.width - originRect.width) * pw,
              originRect.height + (size.height - originRect.height) * ph,
            );

            // ---------- ② 卡片透明度 ----------
            // 抬升段(0→kLiftDurationMs)卡片完全透明，只有封面在动；
            // 展开段才进入透明度斜坡。expMs = 展开段真实毫秒。
            final expMs = (tMs - kLiftDurationMs).clamp(0.0, double.infinity);
            final double cardOpacityRaw;
            if (liftRaw < 1.0) {
              cardOpacityRaw = 0.0;
            } else if (expMs <= kCardOpacityRampMs) {
              cardOpacityRaw = kCardOpacityRampStart +
                  (kCardOpacityStart - kCardOpacityRampStart) *
                      (expMs / kCardOpacityRampMs);
            } else {
              cardOpacityRaw =
                  kCardOpacityStart + (1.0 - kCardOpacityStart) * g;
            }
            final cardOpacity = cardOpacityRaw.clamp(0.0, 1.0);

            // 圆角矩形：前 75% 保持 22，最后 25% 才收方（全程都是圆角矩形）
            final radiusT = ((g - 0.75) / 0.25).clamp(0.0, 1.0);
            final cardRadius = 22.0 * (1 - radiusT);

            // ---------- ③ 复制图 = 缩小版整页 ----------
            // 整页按 s = 卡片宽度 / 屏宽 等比缩小，左上角钉在卡片左上角，裁进卡片。
            // g=1 时 s=1、卡片=满屏，内容正好等于页面本体 —— 终点不需要换图。
            final s = (cardRect.width / size.width).clamp(0.0, 1.0);
            // 交叠进度 u —— 复制图在触发点之前 kCopyFadeLead 就开始淡入：
            //   u=0     复制图刚浮现（原图最实）
            //   触发点   原图「稍比复制图更清晰」（u ≈ 0.43）
            //   u=1     原图完全归零（pw = 0.703，卡片 ≈ 屏宽 82%），复制图完全接管
            final u = ((g - fadeStart) / fadeSpan).clamp(0.0, 1.0);
            final copyFade = u;
            // 原图透明度 = 卡片宽进度的反函数（用户指定）：卡片越小原图越实，卡片越大越透。
            // srcFade = 1 - (g / kSrcFadeEnd)^kSrcFadePow：
            //   g=0（卡140，00:01.51）→ 1.0（最实）；卡片越大越透；
            //   g = kSrcFadeEnd（卡273，00:01.62）→ 0.0（完全透明，此后再不可见）。
            // 缓动指数 >1：前期更实、临近终点才快速变透（「慢慢变淡」）。
            // 与复制图 u 时钟解耦——不再共用（那样会让原图跟复制图同步淡入淡出）。
            final srcFade = (1.0 -
                    math.pow(g / kSrcFadeEnd, kSrcFadePow).toDouble())
                .clamp(0.0, 1.0);

            // ---------- ④ 原图缩放（同一张封面贯穿抬升+展开）----------
            // 抬升段：随 liftEase 从 1.0 放大到峰值 ×1.0357；
            // 展开段（卡片一出来的那一刻起）：钉在卡片左上角，从峰值开始
            // 随卡片宽进度 g 平稳持续缩小，到 kSrcGoneProgress 收到 0（尺寸比透明度收尾更晚）。
            // 不再"先保持峰值再骤缩"。
            final double srcScale;
            if (liftRaw < 1.0) {
              srcScale = 1.0 + (kSrcLiftPeakScale - 1.0) * liftEase;
            } else {
              final t = (g / kSrcGoneProgress).clamp(0.0, 1.0);
              srcScale = kSrcLiftPeakScale *
                  math.pow(1.0 - t, kSrcShrinkPow).toDouble();
            }

            // 旧首页压暗/模糊：与卡片透明度同步渐强
            final dimOpacity = cardOpacity;

            return Stack(
              children: [
                // 1) 旧首页保持可见，被遮罩 + 模糊压暗（纯视觉，不拦截点击）
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: dimOpacity,
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(color: dimColor),
                      ),
                    ),
                  ),
                ),

                // 2) 卡片：白底圆角背景（一直有） + 里面的缩小版整页（复制图）。
                //    Container 负责白底/圆角/阴影/裁剪；内层 Opacity(copyFade) 控制
                //    「复制的图片」什么时候浮现，OverflowBox + Transform.scale(topLeft)
                //    把整页等比缩到 s 倍、左上角对齐卡片左上角，裁进卡片里。
                //    g=1 时 s=1、卡片=满屏，内容就是页面本体 —— 终点不用换图。
                Positioned(
                  left: cardRect.left,
                  top: cardRect.top,
                  width: cardRect.width,
                  height: cardRect.height,
                  child: IgnorePointer(
                    ignoring: g < 0.999,
                    child: Opacity(
                      opacity: cardOpacity,
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(cardRadius),
                          color: surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.50 : 0.18,
                              ),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 复制图：缩小版整页，铺满卡片（左钉）
                            Positioned.fill(
                              child: Opacity(
                                opacity: copyFade,
                                child: OverflowBox(
                                  alignment: Alignment.topLeft,
                                  minWidth: size.width,
                                  maxWidth: size.width,
                                  minHeight: size.height,
                                  maxHeight: size.height,
                                  child: Transform.scale(
                                    scale: s,
                                    alignment: Alignment.topLeft,
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3) 原图（封面）：贯穿「抬升→展开」的同一张，作为卡片兄弟层、独立透明度。
                //    - 抬升段：钉在网格原位、向上位移 liftY*liftEase、放大到峰值，受自身圆角裁切。
                //    - 展开段：钉在卡片左上角（卡片自身已含抬起偏移，故不再额外位移）、
                //      随卡片圆角裁切 → 不会飞出卡片。
                //    透明度只用 srcFade（不被 cardOpacity 压低），所以两阶段衔接处不跳变。
                Positioned(
                  left: liftRaw < 1.0 ? originRect.left : cardRect.left,
                  top: liftRaw < 1.0
                      ? originRect.top - liftY * liftEase
                      : cardRect.top,
                  width: liftRaw < 1.0 ? originRect.width : cardRect.width,
                  height: liftRaw < 1.0 ? originRect.height : cardRect.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      liftRaw < 1.0 ? 12.0 : cardRadius,
                    ),
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: srcFade,
                        child: Transform.scale(
                          scale: srcScale,
                          alignment: Alignment.topLeft,
                          child: _coverBoxWidget(
                            book: book,
                            surface: surface,
                            isDark: isDark,
                            width: originRect.width,
                            height: originRect.height,
                            radius: 12.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

Route<dynamic> _appleOpenRoute(_WordBook book, Rect originRect) {
  return _AppleOpenRoute<dynamic>(book: book, originRect: originRect);
}

/// 正在飞行（打开/返回动画中）的那本书：grid 里对应的**静态封面要隐藏**，
/// 由路由飞行层的「原图」副本接管（抬起→缩小→淡出）。
/// 否则静态图和副本同时显示 → 两张叠在一起（重影）。
/// 返回动画播完（push 的 future resolve）后恢复显示。
final ValueNotifier<_WordBook?> _flyingCoverBook =
    ValueNotifier<_WordBook?>(null);

// 类别顶部横向滚动大横幅（Apple Music Essentials 风格）
class _CategoryBanner extends StatefulWidget {
  const _CategoryBanner();

  @override
  State<_CategoryBanner> createState() => _CategoryBannerState();
}

class _CategoryBannerState extends State<_CategoryBanner> {
  late final PageController _pageController;
  Timer? _autoTimer;
  bool _dragging = false;

  static const Duration _autoInterval = Duration(milliseconds: 2500);
  static const Duration _animDuration = Duration(milliseconds: 600);
  static const int _virtualCount = 1000; // 虚拟页数，实现无缝循环
  static const double _viewportFraction = 0.92; // 卡片占屏宽比例，留边露出邻卡
  static const double _gap = 12.0; // 卡片之间的空隙

  final List<_BannerCard> _cards = const [
    _BannerCard(
      title: 'Forrest Gump',
      subtitle: 'The story of a lifetime.',
      coverColors: [Color(0xFFFF6B9D), Color(0xFFFFC75F)],
      glowColor: Color(0xFFFF8FB1),
      bgColor: Color(0xFF15131E),
      imageAsset: 'assets/images/forrest_gump_cover.jpg',
    ),
    _BannerCard(
      title: 'The Shawshank Redemption',
      subtitle: 'Hope is a good thing.',
      coverColors: [Color(0xFF4CD964), Color(0xFF2C5E3A)],
      glowColor: Color(0xFF8EF0A8),
      bgColor: Color(0xFF12181C),
      imageAsset: 'assets/images/shawshank_cover.jpg',
    ),
    _BannerCard(
      title: 'Titanic',
      subtitle: 'The past lives beneath the waves.',
      coverColors: [Color(0xFFFF6F61), Color(0xFF6B3A58)],
      glowColor: Color(0xFFFFA38F),
      bgColor: Color(0xFF1A1318),
      imageAsset: 'assets/images/titanic_cover.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 从中间页起，保证可向前/向后无缝循环
    _pageController = PageController(
      initialPage: _virtualCount ~/ 2,
      viewportFraction: _viewportFraction,
    );
    _startAutoScroll();
    _bannerAuto.addListener(_onBannerAutoChange);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    _bannerAuto.removeListener(_onBannerAutoChange);
    super.dispose();
  }

  // 主页进入词表页时暂停自动滚动，pop 后恢复 —— 节省性能 + 视觉不乱
  void _onBannerAutoChange() {
    if (!mounted) return;
    if (_bannerAuto.paused) {
      _autoTimer?.cancel();
      _autoTimer = null;
    } else {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (_dragging || !mounted) return;
      _pageController.nextPage(
        duration: _animDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // 单张卡片：Apple 风格渐变封面（主渐变 + 右上角光晕 + 左下角深色 + 左下标题）
  Widget _imageCard(_BannerCard card, double cardW) {
    return Container(
      width: cardW,
      height: 205,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 主层：有图用电影海报，无图才走渐变
          if (card.imageAsset != null)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(card.imageAsset!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: card.coverColors,
                ),
              ),
            ),
          // 右上角径向光晕（Apple featured 高光）
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    card.glowColor.withValues(alpha: 0.55),
                    card.glowColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // 左下角深色压暗，衬托白色文字
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          // 左下角标题 + 副标题
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  card.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    shadows: const [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    // 卡片宽度 = 视口比例对应的像素宽 - 空隙
    final cardW = screenW * _viewportFraction - _gap;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部标题区：小字 FEATURED COLLECTION + 大字标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '视听系列',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '视听融进英语',
                style: TextStyle(
                  color: textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          // 隔离主滚动控制器 + 允许 Web 鼠标拖拽，确保横向滑动不被父级吞掉
          child: PrimaryScrollController.none(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  ui.PointerDeviceKind.touch,
                  ui.PointerDeviceKind.mouse,
                  ui.PointerDeviceKind.trackpad,
                },
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollStartNotification) {
                    _dragging = true;
                    _autoTimer?.cancel();
                  } else if (n is ScrollEndNotification) {
                    _dragging = false;
                    Future.delayed(const Duration(seconds: 4), () {
                      if (mounted && !_dragging) _startAutoScroll();
                    });
                  }
                  return false;
                },
                // 顺序轮播：一张一张平铺播放，卡片稍大、左右露出邻卡边缘，切换平滑滑动无跳变
                child: PageView.builder(
                  controller: _pageController,
                  padEnds: false,
                  allowImplicitScrolling: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _virtualCount,
                  itemBuilder: (context, index) {
                    final card = _cards[index % _cards.length];
                    // 卡片之间留空隙：用 padding 实现（左右各一半 gap）
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
                      child: _imageCard(card, cardW),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard {
  final String title;
  final String subtitle;
  final List<Color> coverColors;
  final Color glowColor;
  final Color bgColor;
  final String? imageAsset;
  const _BannerCard({
    required this.title,
    required this.subtitle,
    required this.coverColors,
    required this.glowColor,
    required this.bgColor,
    this.imageAsset,
  });
}

// 书籍列表区块：标题 + 副标题 + 横向滚动书籍封面
class _BookSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showAll;
  final int count;
  const _BookSection({
    required this.title,
    required this.subtitle,
    this.showAll = false,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 16),
        child: Opacity(opacity: v, child: child),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showAll)
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '显示全部',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: textColor.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: count,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _BookCover(index: i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 书籍封面（占位渐变封面 + 书名 + 作者）
class _BookCover extends StatelessWidget {
  final int index;
  const _BookCover({required this.index});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final titles = [
      'The Midnight Library',
      'Tomorrow, and Tomorrow, and Tomorrow',
      'Lessons in Chemistry',
      'The Thursday Murder Club',
      'Book Lovers',
      'The Seven Moons of Maali Almeida',
      'Sea of Tranquility',
    ];
    final authors = [
      'Matt Haig',
      'Gabrielle Zevin',
      'Bonnie Garmus',
      'Richard Osman',
      'Emily Henry',
      'Shehan Karunatilaka',
      'Emily St. John Mandel',
    ];
    final covers = [
      [const Color(0xFF2E3A59), const Color(0xFF4B5C82)],
      [const Color(0xFF3A3A3C), const Color(0xFF5A5A5E)],
      [const Color(0xFF6E5A4F), const Color(0xFF9C8472)],
      [const Color(0xFF3F5A4E), const Color(0xFF5E7E68)],
      [const Color(0xFF5A4F6E), const Color(0xFF7E729C)],
      [const Color(0xFF6E5F5F), const Color(0xFF9C8A8A)],
      [const Color(0xFF23344F), const Color(0xFF3C557A)],
    ];
    final c = covers[index % covers.length];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 140,
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: c,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.bottomLeft,
            child: Text(
              titles[index % titles.length],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 140,
          child: Text(
            titles[index % titles.length],
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 140,
          child: Text(
            authors[index % authors.length],
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final top = MediaQuery.of(context).padding.top > 0
        ? MediaQuery.of(context).padding.top
        : 54.0;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 20),
      child: Center(
        child: Text(
          '书库',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class BookstorePage extends StatelessWidget {
  const BookstorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final top = MediaQuery.of(context).padding.top > 0
        ? MediaQuery.of(context).padding.top
        : 54.0;
    return Stack(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.fromLTRB(20, top + 8, 20, 20),
          child: Center(
            child: Text(
              'Stepo',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // 旧版底部导航栏（升级液态玻璃之前的外观）放到界面中间
        Center(child: LegacyGlassTabBar(index: 2, onChanged: (_) {})),
      ],
    );
  }
}

// Favorites 页面：iOS 登录风格（头像 + 彩色圆点环 + 学习方式选择）
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    const options = [
      (icon: Icons.format_quote, label: '句子', color: Color(0xFFFF9F0A)),
      (icon: Icons.short_text, label: '短文', color: Color(0xFF32ADE6)),
      (icon: Icons.movie, label: '影视', color: Color(0xFFFF375F)),
      (icon: Icons.menu_book, label: '图书', color: Color(0xFF34C759)),
      (icon: Icons.auto_awesome, label: 'AI 练习', color: Color(0xFFAF52DE)),
      (icon: Icons.album, label: '单词', color: Color(0xFF007AFF)),
    ];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // 头像 + 彩色圆点环（1:1 复刻截图风格）+ 右下角蓝色文件夹图标
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: const _DottedAvatarRing(),
                    ),
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceColor,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.08,
                            ),
                            blurRadius: 24,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: 56,
                        color: textColor.withValues(alpha: 0.35),
                      ),
                    ),
                    // 右下角蓝色文件夹图标（Apple Files / iOS 风格，从头像向外伸出）
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6FB6FF), Color(0xFF1E84FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E84FF)
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: -2,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '选择今天要学习的内容',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.35,
                children: [
                  for (final option in options)
                    _LearningOptionCard(
                      icon: option.icon,
                      label: option.label,
                      color: option.color,
                      onTap: () {},
                    ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// 学习方式选择卡片：Apple 风格大图标 + 文字 + 细阴影
class _LearningOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LearningOptionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 彩色圆点环：围绕头像绘制一圈渐变圆点（iOS 登录/Apple ID 头像风格）
class _DottedAvatarRing extends CustomPainter {
  const _DottedAvatarRing();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 95.0;
    const dotCount = 72;
    const dotRadius = 6.5;

    // 分段颜色，模拟截图：粉→紫→蓝→米棕
    final colors = [
      const Color(0xFFFF6B9D), // pink
      const Color(0xFFFF375F), // red-pink
      const Color(0xFFFFA38F), // peach
      const Color(0xFFAF52DE), // purple
      const Color(0xFF8E7CFF), // violet
      const Color(0xFF32ADE6), // blue
      const Color(0xFF64D2FF), // cyan
      const Color(0xFFD4A574), // beige
      const Color(0xFF8E8E93), // gray
    ];

    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * 3.141592653589793;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      // 圆点大小微微变化，增加呼吸感
      final r = dotRadius * (0.85 + 0.15 * math.sin(i * 0.6));

      // 根据角度映射颜色
      final colorIndex =
          ((i / dotCount) * colors.length).floor() % colors.length;
      final nextColorIndex = (colorIndex + 1) % colors.length;
      final t = ((i / dotCount) * colors.length) - colorIndex;
      final color = Color.lerp(colors[colorIndex], colors[nextColorIndex], t)!;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ╔══════════════════════════════════════════════════════════════════╗
// ║  单词数据模型 + 词表页                                               ║
// ╚══════════════════════════════════════════════════════════════════╝

/// 单个单词：英文 + 音标 + 中文释义
class Word {
  final String text;
  final String phonetic;
  final String meaning;
  const Word(this.text, this.phonetic, this.meaning);
}

/// 用户学习数据库（mock）：实际应持久化到 SharedPreferences/SQLite。
/// 预置 90 个词已学，演示 "90 / 100" 完成度；其中 one..ten 这 10 个数字词模拟未背诵。
const Set<String> _userLearnedWords = {
  'apple',
  'banana',
  'cat',
  'dog',
  'book',
  'pen',
  'pencil',
  'red',
  'blue',
  'green',
  'yellow',
  'teacher',
  'student',
  'school',
  'classroom',
  'friend',
  'family',
  'father',
  'mother',
  'brother',
  'sister',
  'happy',
  'sad',
  'big',
  'small',
  'eat',
  'drink',
  'run',
  'jump',
  'sing',
  'dance',
  'read',
  'write',
  'water',
  'milk',
  'rice',
  'egg',
  'fish',
  'bird',
  'tree',
  'flower',
  'sun',
  'moon',
  'star',
  'hand',
  'foot',
  'head',
  'eye',
  'ear',
  'nose',
  'mouth',
  'hello',
  'goodbye',
  'yes',
  'no',
  'open',
  'close',
  'come',
  'go',
  'play',
  'sleep',
  'morning',
  'evening',
  'name',
  'boy',
  'girl',
  'man',
  'woman',
  'baby',
  'car',
  'bus',
  'bike',
  'train',
  'plane',
  'ball',
  'kite',
  'bag',
  'box',
  'cup',
  'chair',
  'desk',
  'door',
  'window',
  'bed',
  'room',
  'home',
  'time',
  'day',
  'week',
  'year',
};

/// 主页 Banner 自动滚动控制器：进入词表页时 pause，pop 后 resume。
/// 为性能 + 视觉不乱：避免主页后台还在跑 2.5s 翻页动画。
class _BannerAutoController extends ChangeNotifier {
  bool _paused = false;
  bool get paused => _paused;
  void pause() {
    if (_paused) return;
    _paused = true;
    notifyListeners();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    notifyListeners();
  }
}

final _bannerAuto = _BannerAutoController();

/// 词本：标题 + 封面 + 单词列表
class _WordBook {
  final String title;
  final String cover;
  final List<Word> words;
  const _WordBook(this.title, this.cover, this.words);
}

/// 小学英语大纲词汇（100 词）
const List<Word> xiaoxueWords = [
  Word('apple', '/ˈæp.əl/', '苹果'),
  Word('banana', '/bəˈnɑː.nə/', '香蕉'),
  Word('cat', '/kæt/', '猫'),
  Word('dog', '/dɒɡ/', '狗'),
  Word('book', '/bʊk/', '书'),
  Word('pen', '/pen/', '钢笔'),
  Word('pencil', '/ˈpen.səl/', '铅笔'),
  Word('red', '/red/', '红色'),
  Word('blue', '/bluː/', '蓝色'),
  Word('green', '/ɡriːn/', '绿色'),
  Word('yellow', '/ˈjel.əʊ/', '黄色'),
  Word('teacher', '/ˈtiː.tʃə/', '老师'),
  Word('student', '/ˈstjuː.dənt/', '学生'),
  Word('school', '/skuːl/', '学校'),
  Word('classroom', '/ˈklɑːs.ruːm/', '教室'),
  Word('friend', '/frend/', '朋友'),
  Word('family', '/ˈfæm.əl.i/', '家庭'),
  Word('father', '/ˈfɑː.ðə/', '父亲'),
  Word('mother', '/ˈmʌð.ə/', '母亲'),
  Word('brother', '/ˈbrʌð.ə/', '兄弟'),
  Word('sister', '/ˈsɪs.tə/', '姐妹'),
  Word('happy', '/ˈhæp.i/', '高兴的'),
  Word('sad', '/sæd/', '伤心的'),
  Word('big', '/bɪɡ/', '大的'),
  Word('small', '/smɔːl/', '小的'),
  Word('one', '/wʌn/', '一'),
  Word('two', '/tuː/', '二'),
  Word('three', '/θriː/', '三'),
  Word('four', '/fɔː/', '四'),
  Word('five', '/faɪv/', '五'),
  Word('six', '/sɪks/', '六'),
  Word('seven', '/ˈsev.ən/', '七'),
  Word('eight', '/eɪt/', '八'),
  Word('nine', '/naɪn/', '九'),
  Word('ten', '/ten/', '十'),
  Word('eat', '/iːt/', '吃'),
  Word('drink', '/drɪŋk/', '喝'),
  Word('run', '/rʌn/', '跑'),
  Word('jump', '/dʒʌmp/', '跳'),
  Word('sing', '/sɪŋ/', '唱歌'),
  Word('dance', '/dɑːns/', '跳舞'),
  Word('read', '/riːd/', '读'),
  Word('write', '/raɪt/', '写'),
  Word('water', '/ˈwɔː.tə/', '水'),
  Word('milk', '/mɪlk/', '牛奶'),
  Word('rice', '/raɪs/', '米饭'),
  Word('egg', '/eɡ/', '鸡蛋'),
  Word('fish', '/fɪʃ/', '鱼'),
  Word('bird', '/bɜːd/', '鸟'),
  Word('tree', '/triː/', '树'),
  Word('flower', '/ˈflaʊ.ə/', '花'),
  Word('sun', '/sʌn/', '太阳'),
  Word('moon', '/muːn/', '月亮'),
  Word('star', '/stɑː/', '星星'),
  Word('hand', '/hænd/', '手'),
  Word('foot', '/fʊt/', '脚'),
  Word('head', '/hed/', '头'),
  Word('eye', '/aɪ/', '眼睛'),
  Word('ear', '/ɪə/', '耳朵'),
  Word('nose', '/nəʊz/', '鼻子'),
  Word('mouth', '/maʊθ/', '嘴'),
  Word('hello', '/həˈləʊ/', '你好'),
  Word('goodbye', '/ɡʊdˈbaɪ/', '再见'),
  Word('yes', '/jes/', '是'),
  Word('no', '/nəʊ/', '不'),
  Word('open', '/ˈəʊ.pən/', '打开'),
  Word('close', '/kləʊz/', '关闭'),
  Word('come', '/kʌm/', '来'),
  Word('go', '/ɡəʊ/', '去'),
  Word('play', '/pleɪ/', '玩'),
  Word('sleep', '/sliːp/', '睡觉'),
  Word('morning', '/ˈmɔː.nɪŋ/', '早晨'),
  Word('evening', '/ˈiːv.nɪŋ/', '晚上'),
  Word('name', '/neɪm/', '名字'),
  Word('boy', '/bɔɪ/', '男孩'),
  Word('girl', '/ɡɜːl/', '女孩'),
  Word('man', '/mæn/', '男人'),
  Word('woman', '/ˈwʊm.ən/', '女人'),
  Word('baby', '/ˈbeɪ.bi/', '婴儿'),
  Word('car', '/kɑː/', '汽车'),
  Word('bus', '/bʌs/', '公共汽车'),
  Word('bike', '/baɪk/', '自行车'),
  Word('train', '/treɪn/', '火车'),
  Word('plane', '/pleɪn/', '飞机'),
  Word('ball', '/bɔːl/', '球'),
  Word('kite', '/kaɪt/', '风筝'),
  Word('bag', '/bæɡ/', '书包'),
  Word('box', '/bɒks/', '盒子'),
  Word('cup', '/kʌp/', '杯子'),
  Word('chair', '/tʃeə/', '椅子'),
  Word('desk', '/desk/', '书桌'),
  Word('door', '/dɔː/', '门'),
  Word('window', '/ˈwɪn.dəʊ/', '窗户'),
  Word('bed', '/bed/', '床'),
  Word('room', '/ruːm/', '房间'),
  Word('home', '/həʊm/', '家'),
  Word('time', '/taɪm/', '时间'),
  Word('day', '/deɪ/', '白天'),
  Word('week', '/wiːk/', '星期'),
  Word('year', '/jɪə/', '年'),
];

/// 词表页（Apple Music 专辑详情风格）：大封面 + 信息 + 操作按钮 + 分段 Tab + 增量加载词表
class _WordListPage extends StatefulWidget {
  final _WordBook book;

  /// 打开/返回路由 reveal 动画（0→1 打开，1→0 返回），仅用于返回按钮末尾淡入。
  final Animation<double>? reveal;
  const _WordListPage({required this.book, this.reveal});

  @override
  State<_WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<_WordListPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final Set<String> _favorites = <String>{};

  int _selectedTab = 0; // 0 单词 / 1 已收藏 / 2 相关
  int _visibleCount = _kInitialBatch;
  bool _isShuffled = false;
  final List<int> _shuffleOrder = const [];
  bool _loadingMore = false;
  bool _showUnlearnedOnly = false; // 点击副标题 chevron 后只显示未学
  bool _isInShelf = false; // 是否已加入书架列表（未来接 SharedPreferences 持久化）

  // 首屏只预备 10 个单词（iPhone 16 Pro 可视区约 8-10 行，10 个够首屏显示），
  // 往下滑到接近底部再增量加载下一批。
  static const int _kInitialBatch = 10;
  static const int _kBatchSize = 20;

  /// 用户已学单词数（与本词本交集）。
  /// 实际应读取持久化的 _userLearnedWords 全集；这里 mock 一组 25 词。
  int get _learnedCount =>
      widget.book.words.where((w) => _userLearnedWords.contains(w.text)).length;

  List<Word> get _orderedWords {
    if (_isShuffled && _shuffleOrder.length == widget.book.words.length) {
      return _shuffleOrder.map((i) => widget.book.words[i]).toList();
    }
    return widget.book.words;
  }

  List<Word> get _filtered {
    List<Word> base = _orderedWords;
    if (_selectedTab == 1) {
      base = base.where((w) => _favorites.contains(w.text)).toList();
    } else if (_selectedTab == 2) {
      base = base.where((w) => !_favorites.contains(w.text)).toList();
    }
    // 点击副标题 chevron 后：过滤掉已学单词
    if (_showUnlearnedOnly) {
      base = base.where((w) => !_userLearnedWords.contains(w.text)).toList();
    }
    return base;
  }

  List<Word> get _displayed => _filtered.take(_visibleCount).toList();

  bool get _hasMore => _displayed.length < _filtered.length;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadingMore) return;
    final pos = _scrollCtrl.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 160 && _hasMore) {
      if (_loadingMore) return;
      _loadingMore = true;
      setState(() {
        _visibleCount = (_visibleCount + _kBatchSize).clamp(
          0,
          _filtered.length,
        );
      });
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _loadingMore = false;
      });
    }
  }

  void _toggleFavorite(Word w) {
    setState(() {
      if (_favorites.contains(w.text)) {
        _favorites.remove(w.text);
      } else {
        _favorites.add(w.text);
      }
      _visibleCount = _visibleCount.clamp(0, _filtered.length);
    });
  }

  void _toggleUnlearnedOnly() {
    setState(() {
      _showUnlearnedOnly = !_showUnlearnedOnly;
      _visibleCount = _kInitialBatch.clamp(0, _filtered.length);
    });
  }

  /// 点击单词 → 触发发音（占位实现；未来接 flutter_tts 等 TTS 引擎）。
  void _onPronounce(Word w) {
    // TODO: integrate TTS (e.g., flutter_tts: Tts().speak(w.text))
  }

  void _startLearning() {
    setState(() {
      _selectedTab = 0;
      _isShuffled = false;
      _visibleCount = _kInitialBatch.clamp(0, _filtered.length);
    });
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// 「加入书架列表」：toggle 加入/移除书架（未来持久化到 SharedPreferences）。
  void _addToShelf() {
    setState(() {
      _isInShelf = !_isInShelf;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final sub = textColor.withValues(alpha: 0.5);
    final statusHeight = MediaQuery.of(context).viewPadding.top;
    final reveal = widget.reveal ?? const AlwaysStoppedAnimation(1.0);
    final arrowReveal = CurvedAnimation(
      parent: reveal,
      curve: const Interval(0.85, 1.0),
    );

    return Scaffold(
      // 背景用 surface（白/深色），不要透明：
      // 现在卡片 = 缩放版整页，页面背景本身就是卡片背景；
      // 动画期间由路由层的 Container Opacity 控制整体透明度，
      // 动画结束后直接返回 child，背景必须是不透明的，否则会透出旧首页。
      backgroundColor: surface,
      body: Stack(
        children: [
          // 滚动内容：封面 + 标题/进度 + 播放按钮 + 词表（封面随内容上滑，像 Apple Music）
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _AlbumHeader(
                  book: widget.book,
                  isDark: isDark,
                  textColor: textColor,
                  sub: sub,
                  surface: surface,
                  favoriteCount: _favorites.length,
                  learnedCount: _learnedCount,
                  onToggleUnlearned: _toggleUnlearnedOnly,
                  onStart: _startLearning,
                  onAddToShelf: _addToShelf,
                  isInShelf: _isInShelf,
                  reveal: reveal,
                ),
              ),
              ..._buildBody(textColor: textColor, sub: sub, surface: surface),
            ],
          ),
          // 顶部导航条：透明底，返回箭头末尾淡入
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              padding: EdgeInsets.fromLTRB(16, statusHeight + 10, 16, 10),
              child: FadeTransition(
                opacity: arrowReveal,
                child: _NavBar(
                  textColor: textColor,
                  isDark: isDark,
                  onBack: () => appNavigatorKey.currentState?.pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody({
    required Color textColor,
    required Color sub,
    required Color surface,
  }) {
    if (_selectedTab == 2) {
      return [
        SliverToBoxAdapter(
          child: _RelatedPanel(
            total: widget.book.words.length,
            favoriteCount: _favorites.length,
            textColor: textColor,
            sub: sub,
            surface: surface,
          ),
        ),
      ];
    }
    if (_filtered.isEmpty) {
      final msg = widget.book.words.isEmpty ? '该词本尚未导入词汇' : '未找到匹配的单词';
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Text(msg, style: TextStyle(color: sub, fontSize: 14)),
            ),
          ),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          if (i < _displayed.length) {
            final w = _displayed[i];
            return _WordListItem(
              index: i,
              word: w,
              isLearned: _userLearnedWords.contains(w.text),
              isFavorite: _favorites.contains(w.text),
              onFavorite: () => _toggleFavorite(w),
              onPronounce: _onPronounce,
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }, childCount: _displayed.length + (_hasMore ? 1 : 0)),
      ),
    ];
  }
}

// 顶部导航：Apple 同款左右圆形描边按钮（透明底 + 1px 描边，无磨砂填充）
class _NavBar extends StatelessWidget {
  final Color textColor;
  final bool isDark;
  final VoidCallback onBack;
  const _NavBar({
    required this.textColor,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Apple 同款：透明底 + 1px 描边圆按钮（无磨砂填充），干净利落
    final border = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.22);
    Widget circle(IconData icon) => Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: border, width: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(child: Icon(icon, size: 15, color: textColor)),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBack,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: circle(Icons.arrow_back_ios_new)),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // TODO: 分享/导出词本
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: circle(Icons.ios_share_outlined)),
          ),
        ),
      ],
    );
  }
}

// Apple Music 式吸顶折叠头部：
// 展开 = 居中大封面 + 标题/进度 + 红色播放键；
// 下滚时折叠成顶部小条（迷你封面 + 标题）始终吸顶可见。
// 关键：封面永远在屏幕内，因此无论滚到第几个词再返回，
// Hero 飞回起点的矩形都在屏内，彻底消除「从屏幕外飞来」的 bug。
// 专辑页头部：居中大封面 + 居中标题/元信息 + 宽大红色播放按钮
// 纯色背景，不吸顶（封面随内容上滑，像 Apple Music）。
/// 封面盒子：详情页大封面与「深滚返回」时的克隆封面共用，
/// 保证 Hero 飞行两端视觉一致（圆角 / 阴影 / 图片）。
Widget _coverBoxWidget({
  required _WordBook book,
  required Color surface,
  required bool isDark,
  required double width,
  required double height,
  double radius = 20,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        // 与网格页统一：大面积、极淡、极柔的 Apple Books 风格浮起阴影。
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.09),
          blurRadius: 46,
          spreadRadius: -6,
          offset: const Offset(0, 22),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Image.asset(
          book.cover,
          fit: BoxFit.contain,
          cacheWidth: 520,
          frameBuilder: (context, child, frame, sync) {
            if (sync) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (_, _, _) => const ColoredBox(color: Colors.transparent),
        ),
      ),
    ),
  );
}

class _AlbumHeader extends StatelessWidget {
  final _WordBook book;
  final bool isDark;
  final Color textColor;
  final Color sub;
  final Color surface;
  final int favoriteCount;
  final int learnedCount;
  final VoidCallback onToggleUnlearned;
  final VoidCallback onStart;
  final VoidCallback onAddToShelf;
  final bool isInShelf;

  /// 飞行层终点矩形。若不为 null，封面位置和大小必须与飞行层终点完全对齐，
  /// 且封面在 reveal < 1 时隐藏，等飞行层淡出后才显示，避免重影。
  /// 打开/返回路由 reveal 动画。
  final Animation<double>? reveal;

  const _AlbumHeader({
    required this.book,
    required this.isDark,
    required this.textColor,
    required this.sub,
    required this.surface,
    required this.favoriteCount,
    required this.learnedCount,
    required this.onToggleUnlearned,
    required this.onStart,
    required this.onAddToShelf,
    required this.isInShelf,
    this.reveal,
  });

  @override
  Widget build(BuildContext context) {
    final completed = learnedCount >= book.words.length;
    const appleMusicRed = Color(0xFFFA233B);
    // 关键：用 LayoutBuilder 拿**真实布局宽度**，不要用 MediaQuery.of(context).size。
    // iPhone 外壳下 MaterialApp 继承的 MediaQuery 可能是整个浏览器窗口的尺寸，
    // 用它算封面宽度/位置会偏到屏幕外面去。
    final top = MediaQuery.of(context).viewPadding.top + 20.0;
    // 注意：这里**不要**再按 reveal 进度隐藏封面。
    // 卡片渲染的就是整张详情页（_WordListPage）本身，
    // 这张封面是卡片的一部分，必须一直可见；淡入由路由层的 Opacity 统一控制。
    // 若再按 reveal 二次淡入，会变成淡入两次、节奏发闷。
    final revealValue = reveal?.value ?? 1.0;

    return LayoutBuilder(
      builder: (context, c) {
        final mqW = MediaQuery.of(context).size.width;
        final availW = c.maxWidth.isFinite ? c.maxWidth : mqW;
        // 封面保持与网格卡片一致的竖向比例（_cardW : _cardH），避免拉伸。
        // 宽度 = 屏宽 × 0.665：Apple 120Hz 实测复制图（= 详情页封面）全程
        // ≈ 卡片宽 × 0.664，终值 232/349 ≈ 0.6648。
        // 之前用 0.40 会导致复制图相对卡片明显偏小，与 Apple 观感不符。
        const cardRatio =
            _CategoryCardsSection._cardW / _CategoryCardsSection._cardH; // w/h
        final coverW = availW * 0.665;
        final coverH = coverW / cardRatio;

        return Padding(
          padding: EdgeInsets.only(top: top),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _coverBoxWidget(
                book: book,
                surface: surface,
                isDark: isDark,
                width: coverW,
                height: coverH,
              ),
              // 文案/按钮比封面晚一拍淡入（Apple 的错位节奏）：
              // 卡片还小的时候先只看到封面，等长大一些文字才浮出来。
              Opacity(
                opacity: ((revealValue - 0.42) / 0.38).clamp(0.0, 1.0),
                child: _titleBlockWidget(completed),
              ),
              const SizedBox(height: 20),
              Opacity(
                opacity: ((revealValue - 0.52) / 0.34).clamp(0.0, 1.0),
                child: _playButton(appleMusicRed, coverW),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _titleBlockWidget(bool completed) {
    const accent = Color(0xFF34C759);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            book.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (completed)
          Text(
            '100/100',
            style: TextStyle(
              fontSize: 15,
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleUnlearned,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$learnedCount / 100',
                  style: TextStyle(
                    fontSize: 15,
                    color: sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.chevron_right, size: 15, color: sub),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(
          '小学英语 · 入门 · ${book.words.length} 词',
          style: TextStyle(fontSize: 13, color: sub),
        ),
      ],
    );
  }

  Widget _playButton(Color appleMusicRed, double coverSize) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onStart,
      child: Container(
        width: coverSize,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 20, color: appleMusicRed),
            const SizedBox(width: 6),
            Text(
              '开始背诵',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: appleMusicRed,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 描边胶囊按钮：primary 蓝色描边 + 浅蓝填充 / 灰色描边（按压缩放弹簧回弹）
// icon 改为 Widget，方便复用底部导航栏同款字形（如 ✓）
class _ActionButton extends StatefulWidget {
  final String label;
  final Widget icon;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    value: 1,
  );

  // 弹簧参数：质量 1、刚度 500、阻尼 26（按压缩放快速回弹、轻微过冲）
  static const SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 26,
  );

  void _down(_) =>
      _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 0.96, 0));

  void _up(_) =>
      _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 1, 0));

  void _cancel() =>
      _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 1, 0));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF007AFF);
    final border = widget.primary
        ? primary
        : (isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.12));
    final fg = widget.primary
        ? primary
        : Theme.of(context).colorScheme.onSurface;
    final fill = widget.primary
        ? primary.withValues(alpha: 0.08)
        : Colors.transparent;
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      // 用 onTap 触发回调：只要识别为 tap 即触发，比依赖 onTapUp 更可靠
      // （手指轻微滑动时 onTapUp 不会触发，但 onTap 仍会）。
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _ctrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuint,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border, width: 1.0),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon,
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 单词行：序号 + 单词/音标 + 释义 + 未学徽章 + 收藏星标（入场上浮淡入）
// 点击行 → 发音（onPronounce，占位）；点击收藏图标 → 切换收藏
class _WordListItem extends StatelessWidget {
  final int index;
  final Word word;
  final bool isLearned;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final ValueChanged<Word> onPronounce;

  const _WordListItem({
    required this.index,
    required this.word,
    required this.isLearned,
    required this.isFavorite,
    required this.onFavorite,
    required this.onPronounce,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final sub = textColor.withValues(alpha: 0.5);
    final divider = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    // 未背诵单词显示红色「未」标签
    final showE = !isLearned;
    const eColor = Color(0xFFB50000);
    // 只给首屏前 12 行做淡入动画（避免 30 行同时动画在 web 掉帧），
    // 增量加载/滚动复用的行直接显示，保证滚动流畅。
    final animateIn = index < 12;
    return TweenAnimationBuilder<double>(
      key: ValueKey('w_${word.text}'),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: animateIn ? 0 : 1, end: 1),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 8),
          child: child,
        ),
      ),
      child: InkWell(
        onTap: () => onPronounce(word),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: divider, width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.text,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${word.phonetic} · ${word.meaning}',
                      style: TextStyle(fontSize: 13, color: sub),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showE) ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    border: Border.all(color: eColor, width: 1),
                  ),
                  child: const Text(
                    '未',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: eColor,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              _FavoriteButton(isFavorite: isFavorite, onTap: onFavorite),
            ],
          ),
        ),
      ),
    );
  }
}

// 收藏星标：切换时弹簧回弹
class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    value: 1,
  );

  // 弹簧参数：质量 1、刚度 500、阻尼 26（星标弹出 1.3x 后回落）
  static const SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 26,
  );

  @override
  void didUpdateWidget(covariant _FavoriteButton old) {
    super.didUpdateWidget(old);
    if (old.isFavorite != widget.isFavorite) {
      _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 1.3, 0));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final sub = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Icon(
          widget.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: widget.isFavorite ? primary : sub,
          size: 22,
        ),
      ),
    );
  }
}

// 相关页：学习进度环 + 统计卡
class _RelatedPanel extends StatelessWidget {
  final int total;
  final int favoriteCount;
  final Color textColor;
  final Color sub;
  final Color surface;

  const _RelatedPanel({
    required this.total,
    required this.favoriteCount,
    required this.textColor,
    required this.sub,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final pct = total == 0 ? 0.0 : favoriteCount / total;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFE5E5EA),
                    valueColor: AlwaysStoppedAnimation(primary),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '学习进度',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '已收藏 $favoriteCount / $total 个',
                        style: TextStyle(fontSize: 14, color: sub),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '掌握度 ${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 13, color: sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _StatRow(
            label: '总词数',
            value: '$total',
            surface: surface,
            textColor: textColor,
            sub: sub,
          ),
          const SizedBox(height: 10),
          _StatRow(
            label: '已收藏',
            value: '$favoriteCount',
            surface: surface,
            textColor: textColor,
            sub: sub,
          ),
          const SizedBox(height: 10),
          _StatRow(
            label: '难度',
            value: '入门',
            surface: surface,
            textColor: textColor,
            sub: sub,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color surface;
  final Color textColor;
  final Color sub;

  const _StatRow({
    required this.label,
    required this.value,
    required this.surface,
    required this.textColor,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: sub)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

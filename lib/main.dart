import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'iphone_frame.dart';

/// 是否在 Chrome 预览时套 iPhone 16 Pro 真机外壳。
/// true  = `flutter run -d chrome` 直接看到真机框；
/// false = 用项目原有 iphone16_preview.html + localhost:8090 流程（避免双重套框）。
const bool kUseDeviceFrame = true;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    // Web iframe 里 MediaQuery 可能读不到刘海，用 iPhone 16 Pro 的 54pt 兜底
    final statusHeight = MediaQuery.of(context).padding.top > 0
        ? MediaQuery.of(context).padding.top
        : 54.0;
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
                    sigmaX: blurSigma, sigmaY: blurSigma),
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
    const titleSize = 30.0;
    // 外壳状态栏 = 54pt 高，App 内容区起点在屏幕 y=54；灵动岛底部 = top11+height35 = 46。
    // 标题距灵动岛 20pt → 屏幕 y=66 → 在 App 坐标(y-54)里 = 12。
    const titleTop = 12.0;
    final headerHeight = titleTop + titleSize + 10.0;
    // 顶部边缘柔化遮罩：只覆盖状态栏下方极短区域，往下立刻清晰
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
                      onTap: () async {
                        // 进入词表页期间暂停主页 Banner 自动滚动（性能 + 视觉）
                        _bannerAuto.pause();
                        await Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => _WordListPage(book: book),
                          ),
                        );
                        // pop 后恢复（无副作用：仅通知 Banner 监听者）
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
  final VoidCallback onTap;
  const _CategoryBookCover({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: _CategoryCardsSection._cardW,
        height: _CategoryCardsSection._cardH,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 底部书影： screenshot 风格的柔和矩形阴影
            Positioned(
              bottom: -2,
              left: 4,
              right: 4,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 18,
                      spreadRadius: 4,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
            // 书封图片：完整显示上传的原图（BoxFit.contain 不裁剪），加 surface 背景让留白不突兀
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: _CategoryCardsSection._cardW,
                height: _CategoryCardsSection._cardH,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFF2F2F7),
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
          ],
        ),
      ),
    );
  }
}

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

// 单词类别下的书籍卡片（Apple Books 封面占位）
class _CategoryBookCards extends StatelessWidget {
  const _CategoryBookCards();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final books = [
      (
        'The Midnight Library',
        'Matt Haig',
        const Color(0xFF3A4A6B),
        const Color(0xFFD8E0F0),
      ),
      (
        'Tomorrow, and Tomorrow, and Tomorrow',
        'Gabrielle Zevin',
        const Color(0xFF4A4A4A),
        const Color(0xFFE8E8E8),
      ),
      (
        'Lessons in Chemistry',
        'Bonnie Garmus',
        const Color(0xFF7B5E4E),
        const Color(0xFFF0E6DF),
      ),
    ];
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (title, author, coverColor, _) = books[index];
          return SizedBox(
            width: 115,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 115,
                  height: 152,
                  decoration: BoxDecoration(
                    color: coverColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  author,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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
  'apple', 'banana', 'cat', 'dog', 'book', 'pen', 'pencil',
  'red', 'blue', 'green', 'yellow', 'teacher', 'student',
  'school', 'classroom', 'friend', 'family', 'father',
  'mother', 'brother', 'sister', 'happy', 'sad', 'big', 'small',
  'eat', 'drink', 'run', 'jump', 'sing', 'dance', 'read', 'write',
  'water', 'milk', 'rice', 'egg', 'fish', 'bird', 'tree', 'flower',
  'sun', 'moon', 'star', 'hand', 'foot', 'head', 'eye', 'ear',
  'nose', 'mouth', 'hello', 'goodbye', 'yes', 'no', 'open', 'close',
  'come', 'go', 'play', 'sleep', 'morning', 'evening', 'name',
  'boy', 'girl', 'man', 'woman', 'baby', 'car', 'bus', 'bike',
  'train', 'plane', 'ball', 'kite', 'bag', 'box', 'cup', 'chair',
  'desk', 'door', 'window', 'bed', 'room', 'home', 'time', 'day',
  'week', 'year',
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
  const _WordListPage({required this.book});

  @override
  State<_WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<_WordListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final Set<String> _favorites = <String>{};

  int _selectedTab = 0; // 0 单词 / 1 已收藏 / 2 相关
  int _visibleCount = _kInitialBatch;
  bool _isShuffled = false;
  List<int> _shuffleOrder = const [];
  bool _loadingMore = false;
  bool _showUnlearnedOnly = false; // 点击副标题 chevron 后只显示未学
  bool _isInShelf = false; // 是否已加入书架列表（未来接 SharedPreferences 持久化）

  // 首屏只预备 10 个单词（iPhone 16 Pro 可视区约 8-10 行，10 个够首屏显示），
  // 往下滑到接近底部再增量加载下一批 —— 首帧轻，push 动画不被拖垮。
  static const int _kInitialBatch = 10;
  static const int _kBatchSize = 20;

  /// 用户已学单词数（与本词本交集）。
  /// 实际应读取持久化的 _userLearnedWords 全集；这里 mock 一组 25 词。
  int get _learnedCount => widget.book.words
      .where((w) => _userLearnedWords.contains(w.text))
      .length;

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
      base =
          base.where((w) => !_userLearnedWords.contains(w.text)).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base
        .where((w) => w.text.toLowerCase().contains(q))
        .toList();
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
    _searchCtrl.dispose();
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

  void _onSearchChanged() {
    setState(() {
      _visibleCount = _kInitialBatch.clamp(0, _filtered.length);
    });
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
    _searchCtrl.clear();
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
    final bg = isDark ? const Color(0xFF010101) : const Color(0xFFFFFFFF);
    final surface = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final sub = textColor.withValues(alpha: 0.5);
    final statusHeight = MediaQuery.of(context).padding.top;
    final gapCoverButtons = MediaQuery.of(context).size.height * 0.032;
    // 粘性头部高度 = 状态栏 + 10(上内边距) + 38(NavBar) + 34(间距) + 128(封面) + gapCoverButtons + 32(按钮) + 14(间距) + 56(搜索框)
    final headerHeight = statusHeight +
        10 +
        38 +
        34 +
        128 +
        gapCoverButtons +
        32 +
        14 +
        56;

    final panelColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.60);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 底层：列表从 y=0 开始绘制，先留出 header 高度避免首屏被挡住
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
              ..._buildBody(textColor: textColor, sub: sub, surface: surface),
            ],
          ),
          // 顶层：固定磨砂玻璃头部（浮在列表上方，列表项会从后面滑过并被模糊）
          // 从 y=0 起、左右贴边 → 整条（含灵动岛/状态栏区域）都是毛玻璃
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                // 模糊层外扩 8pt，避免边缘被裁剪产生暗边/阴影
                Positioned(
                  top: -8,
                  left: -8,
                  right: -8,
                  bottom: -8,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // 可见磨砂面板：无底部边框，避免那条黑带
                Container(
                  color: panelColor,
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NavBar(textColor: textColor, isDark: isDark),
                          const SizedBox(height: 34),
                          _AlbumHeader(
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
                          ),
                          const SizedBox(height: 14),
                          _SearchBar(
                            controller: _searchCtrl,
                            surface: surface,
                            sub: sub,
                            textColor: textColor,
                            onChanged: _onSearchChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

// 顶部导航：只保留返回按钮（iOS 风细线条箭头，和底部导航图标设计语言统一）
class _NavBar extends StatelessWidget {
  final Color textColor;
  final bool isDark;
  const _NavBar({required this.textColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: textColor,
        ),
      ),
    );
  }
}

// 大封面 + 标题/进度 + 操作按钮（Apple Music 专辑头部）
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
  });

  @override
  Widget build(BuildContext context) {
    final completed = learnedCount >= book.words.length;
    const accent = Color(0xFF34C759); // Apple 系统绿
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面：解码后淡入（不做 Hero 飞行，保证 push/pop 是纯 Apple 左右滑动）
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                    blurRadius: 10,
                    spreadRadius: -1,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  color: surface,
                  alignment: Alignment.center,
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
                    errorBuilder: (_, _, _) => Container(color: surface),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
// 进度行：>= 总词数 → 绿色 100/100 + 无 chevron；
  //             < 总词数 → X/100 + chevron，点击切换"只显示未学"
  if (completed)
                    Text(
                      '100/100',
                      style: TextStyle(
                        fontSize: 14,
                        color: accent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    )
                  else
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggleUnlearned,
                      child: Row(
                        children: [
                          Text(
                            '$learnedCount / 100',
                            style: TextStyle(
                              fontSize: 14,
                              color: sub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 14, color: sub),
                        ],
                      ),
                    ),
                    // 已学 X/100 + chevron 触发"只显示未学"
                  const SizedBox(height: 6),
                  Text(
                    '本书 ${book.words.length} 词',
                    style: TextStyle(fontSize: 13, color: sub),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.032),
        // 不加 AnimatedSize：点「加入/已加入」时左按钮原地切换文案，
        // 「开始背诵」位置固定不动（无推动动画）
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 未加入 / 已加入：外框颜色不变，只换图标和文案
            _ActionButton(
              label: isInShelf ? '已加入书架列表' : '加入书架列表',
              icon: isInShelf
                  ? Text('✓',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: textColor,
                      ))
                  : Icon(Icons.bookmark_add_outlined,
                      size: 14, color: textColor),
              primary: false,
              onTap: onAddToShelf,
            ),
            const SizedBox(width: 10),
            _ActionButton(
              label: '开始背诵',
              icon: Icon(Icons.play_arrow, size: 14, color: textColor),
              primary: false,
              onTap: onStart,
            ),
          ],
        ),
      ],
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

// 搜索框：描边胶囊设计（与「开始背诵」按钮一致），仅搜索单词
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Color surface;
  final Color sub;
  final Color textColor;
  final VoidCallback onChanged;

  const _SearchBar({
    required this.controller,
    required this.surface,
    required this.sub,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.12);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search,
              color: sub,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1,
                ),
                decoration: InputDecoration(
                  hintText: '搜索单词',
                  hintStyle: TextStyle(color: sub, fontSize: 14, height: 1),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
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
            border: Border(
              bottom: BorderSide(color: divider, width: 0.5),
            ),
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

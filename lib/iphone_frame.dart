import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iPhone 16 Pro 真机外壳，用于在 Chrome 里预览时呈现真实设备效果。
/// 设备逻辑尺寸：393 × 852 pt（6.3" / 460 ppi）。
///
/// 用法：在 main 里用 `kUseDeviceFrame` 开关把 App 包一层即可：
///   kUseDeviceFrame
///     ? IPhone16ProFrame(isDark: ..., child: app)
///     : app
class IPhone16ProFrame extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const IPhone16ProFrame({
    super.key,
    required this.child,
    required this.isDark,
  });

  static const double _deviceWidth = 393;
  static const double _deviceHeight = 852;
  static const double _bezel = 12; // 钛金属边框宽度
  static const double _deviceRadius = 55;
  static const double _screenRadius = 47;
  static const double _statusBarHeight = 54;
  static const double _homeIndicatorHeight = 34;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // 让 App 内容铺满整块屏幕（包括状态栏/灵动岛/Home 指示条区域），
    // 但把安全边距通过 viewPadding 告诉 App，方便它自己决定哪些元素需要避让。
    final deviceMedia = mq.copyWith(
      padding: EdgeInsets.zero,
      viewPadding: const EdgeInsets.only(
        top: _statusBarHeight,
        bottom: _homeIndicatorHeight,
      ),
    );

    return Container(
      color: const Color(0xFF1C1C1E),
      alignment: Alignment.center,
      child: Container(
        width: _deviceWidth,
        height: _deviceHeight,
        decoration: BoxDecoration(
          // 钛金属边框渐变
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8A8A8E), Color(0xFFE3E3E6), Color(0xFF6E6E73)],
          ),
          borderRadius: BorderRadius.circular(_deviceRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(_bezel),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_screenRadius),
          child: Container(
            color: isDark ? const Color(0xFF010101) : Colors.white,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  // App 内容：铺满全屏，可以延伸到状态栏 / Home 指示条下面
                  Positioned.fill(
                    child: MediaQuery(
                      data: deviceMedia,
                      child: child,
                    ),
                  ),
                  // 状态栏（透明背景，浮在内容之上，不拦截点击）
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: _statusBarHeight,
                    child: IgnorePointer(
                      child: _StatusBar(isDark: isDark),
                    ),
                  ),
                  // 灵动岛（不拦截点击）
                  const Positioned(
                    top: 11,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: _DynamicIsland(),
                    ),
                  ),
                  // Home 指示条（透明背景，浮在内容之上，不拦截点击）
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: _homeIndicatorHeight,
                    child: IgnorePointer(
                      child: _HomeIndicator(isDark: isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final bool isDark;

  const _StatusBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.2,
              decoration: TextDecoration.none,
            ),
          ),
          Row(
            children: [
              Icon(
                CupertinoIcons.antenna_radiowaves_left_right,
                size: 17,
                color: fg,
              ),
              const SizedBox(width: 6),
              Icon(CupertinoIcons.wifi, size: 16, color: fg),
              const SizedBox(width: 6),
              _BatteryIndicator(color: fg),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatteryIndicator extends StatelessWidget {
  final Color color;

  const _BatteryIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 27,
      height: 13,
      child: Stack(
        children: [
          Container(
            width: 24,
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.2),
              borderRadius: BorderRadius.circular(3.5),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 17,
                height: 8,
                margin: const EdgeInsets.only(left: 1.5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.8),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 3.5,
            child: Container(
              width: 1.6,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 122,
        height: 35,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  final bool isDark;

  const _HomeIndicator({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 134,
        height: 5,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}

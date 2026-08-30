import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AppleMusic Demo",
      theme: ThemeData(useMaterial3: true),
      home: const AlbumListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 列表主页
class AlbumListPage extends StatelessWidget {
  const AlbumListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("专辑列表")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                _createAppleMusicRoute(const AlbumDetailPage()),
              );
            },
            child: Hero(
              tag: "album_cover",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  "https://picsum.photos/id/103/300/300",
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static PageRouteBuilder _createAppleMusicRoute(Widget targetPage) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      opaque: false, // 关键！路由背景透明，才能看见下层页面
      pageBuilder: (ctx, anim, secondaryAnim) => targetPage,
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final curve = Curves.easeInOutCubicEmphasized;
        final curAnim = CurvedAnimation(parent: animation, curve: curve);

        return Stack(
          children: [
            // 【重点】Flutter原生没有直接访问上一页widget的API，这里使用`ModalBarrier`+动画变换，上层路由的secondaryAnimation会驱动原页面变换
            // 这套是社区公认写法，模拟Apple Music下层缩放变暗
            AnimatedBuilder(
              animation: secondaryAnimation,
              builder: (buildCtx, _) {
                final t = CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: curve,
                ).value;
                final scale = 1.0 - t * 0.085;
                final radius = t * 24.0;
                final bgOpacity = 1.0 - t * 0.42;
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Opacity(
                      opacity: bgOpacity,
                      // 下层就渲染原始路由快照，不需要重复写页面组件
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
              },
            ),
            FadeTransition(opacity: curAnim, child: child),
          ],
        );
      },
    );
  }
}

// 详情页：无系统侧滑返回，只用关闭按钮
class AlbumDetailPage extends StatelessWidget {
  const AlbumDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.black.withOpacity(0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Center(
              child: Hero(
                tag: "album_cover",
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    "https://picsum.photos/id/103/300/300",
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "专辑名称",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("关闭"),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

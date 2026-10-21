import 'package:flutter/material.dart';
import '../theme/ui_colors.dart';

const Color _base = Color(0xFFE4E4E8);
const Color _shine = Color(0xFFF6F6F8);

/// Sweeps a light shine across its child (the child should be made of
/// [SkeletonBox]es). One animation drives the whole skeleton.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _SlideGradient extends GradientTransform {
  final double progress; // 0..1
  const _SlideGradient(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
        bounds.width * (progress * 2 - 1), 0, 0);
  }
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            colors: const [_base, _shine, _base],
            stops: const [0.35, 0.5, 0.65],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: _SlideGradient(_c.value),
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonPage extends StatelessWidget {
  final List<Widget> children;
  const _SkeletonPage({required this.children});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: UiColors.bg,
      child: Shimmer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder for the Withdraw screen.
class WithdrawSkeleton extends StatelessWidget {
  const WithdrawSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonPage(children: [
      SkeletonBox(width: 150, height: 32, radius: 10),
      SizedBox(height: 16),
      SkeletonBox(height: 130, radius: 28),
      SizedBox(height: 14),
      SkeletonBox(height: 112, radius: 24),
      SizedBox(height: 16),
      SkeletonBox(height: 52, radius: 40),
      SizedBox(height: 16),
      SkeletonBox(height: 200, radius: 24),
    ]);
  }
}

/// Loading placeholder for the Wallet screen.
class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonPage(children: [
      SkeletonBox(width: 120, height: 32, radius: 10),
      SizedBox(height: 16),
      SkeletonBox(height: 120, radius: 28),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: SkeletonBox(height: 100, radius: 24)),
          SizedBox(width: 10),
          Expanded(child: SkeletonBox(height: 100, radius: 24)),
          SizedBox(width: 10),
          Expanded(child: SkeletonBox(height: 100, radius: 24)),
        ],
      ),
      SizedBox(height: 16),
      SkeletonBox(height: 52, radius: 40),
      SizedBox(height: 26),
      SkeletonBox(width: 190, height: 24, radius: 8),
      SizedBox(height: 12),
      SkeletonBox(height: 66, radius: 22),
      SizedBox(height: 10),
      SkeletonBox(height: 66, radius: 22),
      SizedBox(height: 10),
      SkeletonBox(height: 66, radius: 22),
    ]);
  }
}

/// Loading placeholder for the Home screen.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonPage(children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 110, height: 14, radius: 6),
                SizedBox(height: 8),
                SkeletonBox(width: 170, height: 28, radius: 10),
              ],
            ),
          ),
          SkeletonBox(width: 46, height: 46, radius: 23),
        ],
      ),
      SizedBox(height: 18),
      SkeletonBox(height: 128, radius: 28),
      SizedBox(height: 14),
      SkeletonBox(height: 186, radius: 28),
      SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: SkeletonBox(height: 104, radius: 24)),
          SizedBox(width: 10),
          Expanded(child: SkeletonBox(height: 104, radius: 24)),
          SizedBox(width: 10),
          Expanded(child: SkeletonBox(height: 104, radius: 24)),
        ],
      ),
      SizedBox(height: 22),
      SkeletonBox(width: 180, height: 24, radius: 8),
      SizedBox(height: 12),
      SkeletonBox(height: 96, radius: 24),
      SizedBox(height: 10),
      SkeletonBox(height: 96, radius: 24),
    ]);
  }
}
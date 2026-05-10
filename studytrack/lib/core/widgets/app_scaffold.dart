import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// A theme-aware scaffold with optional ambient brand-colored glow blobs
/// painted behind the content. Use this on every full-page screen so
/// light/dark transitions render flawlessly.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.ambientGlow = true,
    this.ambientIntensity = 1.0,
    this.useDeepBackground = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool ambientGlow;
  final double ambientIntensity;
  final bool useDeepBackground;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = useDeepBackground
        ? palette.backgroundDeep
        : palette.background;
    return Scaffold(
      backgroundColor: background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: ambientGlow
          ? Stack(
              children: [
                Positioned.fill(
                  child: AmbientGlowBackground(intensity: ambientIntensity),
                ),
                body,
              ],
            )
          : body,
    );
  }
}

/// Two large soft-radial blurs that paint subtle brand color behind any
/// screen. Adapts to light vs dark and is intentionally low-opacity in
/// light mode so it doesn't compete with content.
class AmbientGlowBackground extends StatelessWidget {
  const AmbientGlowBackground({super.key, this.intensity = 1.0});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: _GlowBlob(
              size: 260,
              color: palette.ambientGlowPrimary.withValues(
                alpha: palette.ambientGlowPrimary.a * intensity,
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -110,
            child: _GlowBlob(
              size: 220,
              color: palette.ambientGlowSecondary.withValues(
                alpha: palette.ambientGlowSecondary.a * intensity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

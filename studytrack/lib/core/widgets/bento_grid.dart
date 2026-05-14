import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Bento Grid primitives — deliberate, editor-controlled tile layouts.
///
/// No staggered-grid package. Each row composes tiles with `flex` and an
/// optional `height`/`aspectRatio`. The designer picks tile sizes per row;
/// nothing auto-flows. That's intentional — bento is editorial, not
/// algorithmic.
///
/// Usage:
/// ```dart
/// BentoGrid(
///   rows: [
///     BentoRow(height: 180, children: [
///       BentoTile(flex: 2, child: _SpotlightCard()),
///       BentoTile(flex: 1, child: _CompactCard()),
///     ]),
///     BentoRow(height: 120, children: [
///       BentoTile(child: _A()),
///       BentoTile(child: _B()),
///     ]),
///   ],
/// )
/// ```
class BentoGrid extends StatelessWidget {
  const BentoGrid({
    required this.rows,
    super.key,
    this.spacing = AppSpacing.itemGap,
  });

  final List<BentoRow> rows;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(SizedBox(height: spacing));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// A single row in a [BentoGrid]. Holds 1–4 tiles laid out by their `flex`.
///
/// If [height] is given, every tile in the row matches that height.
/// Otherwise the row sizes to the tallest tile via [IntrinsicHeight].
class BentoRow extends StatelessWidget {
  const BentoRow({
    required this.children,
    super.key,
    this.height,
    this.spacing = AppSpacing.itemGap,
  });

  final List<BentoTile> children;
  final double? height;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      tiles.add(Expanded(flex: children[i].flex, child: children[i]));
      if (i < children.length - 1) {
        tiles.add(SizedBox(width: spacing));
      }
    }
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tiles,
    );
    if (height != null) {
      return SizedBox(height: height, child: row);
    }
    return IntrinsicHeight(child: row);
  }
}

/// A single bento tile — surfaced card with a 0.5 px hairline border.
///
/// `flex` controls horizontal span (1 = standard, 2 = double-wide, etc.).
/// Use [BentoTile.feature] for the editorial spotlight (signal-tinted border),
/// [BentoTile.muted] for secondary info (soft border, dimmer surface).
class BentoTile extends StatelessWidget {
  const BentoTile({
    required this.child,
    super.key,
    this.flex = 1,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderColor,
    this.backgroundColor,
    this.borderRadius,
  });

  /// Spotlight tile — signal-tinted hairline border for the screen's primary
  /// piece of information.
  const BentoTile.feature({
    required this.child,
    super.key,
    this.flex = 2,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.backgroundColor,
    this.borderRadius,
  }) : borderColor = AppColors.signal;

  /// Secondary tile — soft border, slightly dimmer fill.
  const BentoTile.muted({
    required this.child,
    super.key,
    this.flex = 1,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderRadius,
  }) : borderColor = AppColors.borderDarkSoft,
       backgroundColor = AppColors.cardDarkAlt;

  final Widget child;
  final int flex;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.cardRadius);
    final bg =
        backgroundColor ??
        (isLight ? AppColors.surfaceLight : AppColors.surfaceDark);
    final border =
        borderColor ?? (isLight ? AppColors.borderLight : AppColors.borderDark);

    final content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 0.5),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.signalSubtle,
        highlightColor: AppColors.signalSubtle,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}

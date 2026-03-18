import 'package:flutter/material.dart';

class LayerPanelTokens {
  final LayerPanelColors colors;
  final LayerPanelSizes sizes;
  final LayerPanelPadding padding;
  final LayerPanelRadius radius;
  final LayerPanelOpacity opacity;

  const LayerPanelTokens({
    required this.colors,
    required this.sizes,
    required this.padding,
    required this.radius,
    required this.opacity,
  });

  static const light = LayerPanelTokens(
    colors: LayerPanelColors(
      background: Color(0xFFF9FAFB),
      border: Color(0xFFE5E7EB),
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      textMuted: Color(0xFF9CA3AF),
      iconMuted: Color(0xFF94A3B8),
      stateAccent: Color(0xFF2563EB),
      rowSelected: Color(0x142563EB),
      rowHover: Color(0x0A2563EB),
      dragFeedbackBackground: Color(0xFFFFFFFF),
      dragFeedbackShadowColor: Color(0x1A0F172A),
    ),
    sizes: LayerPanelSizes(
      width: 220,
      leadingSlotSize: 24,
      leadingIconSize: 16,
      expandIconSize: 18,
      trailingIconSize: 16,
      headerIconSize: 16,
      headerButtonSize: 28,
      dropIndicatorHeight: 2,
      dragFeedbackShadowBlurRadius: 18,
      dragFeedbackShadowOffset: Offset(0, 10),
    ),
    padding: LayerPanelPadding(
      outer: EdgeInsets.all(8),
      headerToListSpacing: 8,
      rowBaseLeft: 6,
      rowIndentPerDepth: 10,
      rowRight: 2,
      rowVertical: 4,
      itemIconTextSpacing: 6,
      dragFeedbackRight: 10,
      dragFeedbackVertical: 6,
    ),
    radius: LayerPanelRadius(
      row: 6,
      dragFeedback: 8,
      dropIndicator: 999,
    ),
    opacity: LayerPanelOpacity(
      rowDragging: 0.35,
      rowHidden: 0.6,
      dragFeedback: 0.9,
    ),
  );

  static const dark = LayerPanelTokens(
    colors: LayerPanelColors(
      background: Color(0xFF0B1220),
      border: Color(0xFF1F2937),
      textPrimary: Color(0xFFF9FAFB),
      textSecondary: Color(0xFFCBD5E1),
      textMuted: Color(0xFF94A3B8),
      iconMuted: Color(0xFF94A3B8),
      stateAccent: Color(0xFF60A5FA),
      rowSelected: Color(0x1A60A5FA),
      rowHover: Color(0x0F60A5FA),
      dragFeedbackBackground: Color(0xFF111827),
      dragFeedbackShadowColor: Color(0x66000000),
    ),
    sizes: LayerPanelSizes(
      width: 220,
      leadingSlotSize: 24,
      leadingIconSize: 16,
      expandIconSize: 18,
      trailingIconSize: 16,
      headerIconSize: 16,
      headerButtonSize: 28,
      dropIndicatorHeight: 2,
      dragFeedbackShadowBlurRadius: 18,
      dragFeedbackShadowOffset: Offset(0, 10),
    ),
    padding: LayerPanelPadding(
      outer: EdgeInsets.all(8),
      headerToListSpacing: 8,
      rowBaseLeft: 6,
      rowIndentPerDepth: 10,
      rowRight: 2,
      rowVertical: 4,
      itemIconTextSpacing: 6,
      dragFeedbackRight: 10,
      dragFeedbackVertical: 6,
    ),
    radius: LayerPanelRadius(
      row: 6,
      dragFeedback: 8,
      dropIndicator: 999,
    ),
    opacity: LayerPanelOpacity(
      rowDragging: 0.35,
      rowHidden: 0.6,
      dragFeedback: 0.9,
    ),
  );
}

class LayerPanelColors {
  final Color background;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color iconMuted;
  final Color stateAccent;
  final Color rowSelected;
  final Color rowHover;
  final Color dragFeedbackBackground;
  final Color dragFeedbackShadowColor;

  const LayerPanelColors({
    required this.background,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.iconMuted,
    required this.stateAccent,
    required this.rowSelected,
    required this.rowHover,
    required this.dragFeedbackBackground,
    required this.dragFeedbackShadowColor,
  });
}

class LayerPanelSizes {
  final double width;
  final double leadingSlotSize;
  final double leadingIconSize;
  final double expandIconSize;
  final double trailingIconSize;
  final double headerIconSize;
  final double headerButtonSize;
  final double dropIndicatorHeight;
  final double dragFeedbackShadowBlurRadius;
  final Offset dragFeedbackShadowOffset;

  const LayerPanelSizes({
    required this.width,
    required this.leadingSlotSize,
    required this.leadingIconSize,
    required this.expandIconSize,
    required this.trailingIconSize,
    required this.headerIconSize,
    required this.headerButtonSize,
    required this.dropIndicatorHeight,
    required this.dragFeedbackShadowBlurRadius,
    required this.dragFeedbackShadowOffset,
  });
}

class LayerPanelPadding {
  final EdgeInsets outer;
  final double headerToListSpacing;
  final double rowBaseLeft;
  final double rowIndentPerDepth;
  final double rowRight;
  final double rowVertical;
  final double itemIconTextSpacing;
  final double dragFeedbackRight;
  final double dragFeedbackVertical;

  const LayerPanelPadding({
    required this.outer,
    required this.headerToListSpacing,
    required this.rowBaseLeft,
    required this.rowIndentPerDepth,
    required this.rowRight,
    required this.rowVertical,
    required this.itemIconTextSpacing,
    required this.dragFeedbackRight,
    required this.dragFeedbackVertical,
  });
}

class LayerPanelRadius {
  final double row;
  final double dragFeedback;
  final double dropIndicator;

  const LayerPanelRadius({
    required this.row,
    required this.dragFeedback,
    required this.dropIndicator,
  });
}

class LayerPanelOpacity {
  final double rowDragging;
  final double rowHidden;
  final double dragFeedback;

  const LayerPanelOpacity({
    required this.rowDragging,
    required this.rowHidden,
    required this.dragFeedback,
  });
}

@immutable
class LayerPanelTheme extends ThemeExtension<LayerPanelTheme> {
  final LayerPanelTokens tokens;

  const LayerPanelTheme({required this.tokens});

  @override
  LayerPanelTheme copyWith({LayerPanelTokens? tokens}) {
    return LayerPanelTheme(tokens: tokens ?? this.tokens);
  }

  @override
  LayerPanelTheme lerp(ThemeExtension<LayerPanelTheme>? other, double t) {
    if (other is! LayerPanelTheme) return this;
    return t < 0.5 ? this : other;
  }
}

extension LayerPanelThemeBuildContextX on BuildContext {
  LayerPanelTokens get layerPanelTokens {
    final ext = Theme.of(this).extension<LayerPanelTheme>();
    if (ext != null) return ext.tokens;
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? LayerPanelTokens.dark
        : LayerPanelTokens.light;
  }
}

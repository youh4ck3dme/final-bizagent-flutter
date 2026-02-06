import 'package:flutter/material.dart';

/// Centralized BizAgent logo widget.
/// Always renders the correct brand logo from assets/images/brand/logo_mark.png.
/// Use this widget everywhere the BizAgent logo needs to appear in UI.
///
/// DO NOT use the launcher icon assets (icon, icon_fg) in UI - those are for
/// Android/iOS system level only. Always use this widget instead.
class BizLogoMark extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const BizLogoMark({
    super.key,
    this.size = 88,
    this.fit = BoxFit.contain,
  });

  /// The canonical path to the brand logo asset.
  static const String assetPath = 'assets/images/brand/logo_mark.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
    );
  }
}

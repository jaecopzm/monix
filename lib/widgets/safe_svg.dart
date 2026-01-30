import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SafeSvg extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;
  final String fallbackEmoji;

  const SafeSvg({
    super.key,
    required this.asset,
    this.size = 24,
    this.color,
    this.fallbackEmoji = '💠',
  });

  @override
  Widget build(BuildContext context) {
    try {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => SizedBox(
          width: size,
          height: size,
        ),
        fit: BoxFit.contain,
        theme: const SvgTheme(currentColor: Colors.black),
      );
    } catch (e) {
      debugPrint('SafeSvg error loading $asset: $e');
      return Text(
        fallbackEmoji,
        style: TextStyle(fontSize: size * 0.8),
      );
    }
  }
}

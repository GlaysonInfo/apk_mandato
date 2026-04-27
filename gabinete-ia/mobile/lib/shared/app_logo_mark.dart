import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppLogoVariant {
  auto,
  symbol,
  wordmark,
}

class AppLogoMark extends StatelessWidget {
  final double size;
  final bool showHalo;
  final AppLogoVariant variant;

  const AppLogoMark({
    super.key,
    this.size = 108,
    this.showHalo = true,
    this.variant = AppLogoVariant.auto,
  });

  static const String _symbolAsset = 'assets/images/brand_symbol.svg';

  @override
  Widget build(BuildContext context) {
    if (variant == AppLogoVariant.wordmark || (variant == AppLogoVariant.auto && size >= 90)) {
      return _BrandWordmark(size: size, showHalo: showHalo);
    }

    return _BrandSymbol(size: size, showHalo: showHalo);
  }
}

class _BrandSymbol extends StatelessWidget {
  final double size;
  final bool showHalo;

  const _BrandSymbol({required this.size, required this.showHalo});

  @override
  Widget build(BuildContext context) {
    final symbol = SvgPicture.asset(
      AppLogoMark._symbolAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!showHalo) {
      return SizedBox(width: size, height: size, child: symbol);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC5F4).withValues(alpha: 0.22),
            blurRadius: size * 0.28,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: symbol,
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  final double size;
  final bool showHalo;

  const _BrandWordmark({required this.size, required this.showHalo});

  @override
  Widget build(BuildContext context) {
    final symbolSize = size * 0.9;
    final titleSize = size * 0.22;
    final brandSize = size * 0.38;
    final captionSize = size * 0.16;
    final compact = size < 90;

    return Container(
      constraints: BoxConstraints(minHeight: size, maxWidth: compact ? size * 4.2 : size * 3.35),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? size * 0.12 : size * 0.14,
        vertical: compact ? size * 0.08 : size * 0.12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A5F94), Color(0xFF0A3D73)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E3C6E).withValues(alpha: 0.18),
            blurRadius: size * 0.34,
            offset: Offset(0, size * 0.12),
          ),
          if (showHalo)
            BoxShadow(
              color: const Color(0xFF49C4F1).withValues(alpha: 0.18),
              blurRadius: size * 0.24,
              spreadRadius: size * 0.02,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrandSymbol(size: compact ? size * 0.76 : symbolSize, showHalo: false),
          SizedBox(width: size * 0.12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inteligência de',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? size * 0.18 : titleSize,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7FD7FF), Color(0xFF2B8DE3), Color(0xFFE8ED7F)],
                  ).createShader(bounds),
                  child: Text(
                    'GABINETE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? size * 0.30 : brandSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 0.2 : 0.4,
                      height: 0.96,
                    ),
                  ),
                ),
                if (!compact) ...[
                  SizedBox(height: size * 0.03),
                  Text(
                    'Sistema de Gestão Política',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFF3D86F),
                      fontSize: captionSize,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
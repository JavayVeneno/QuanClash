import 'package:flutter/material.dart';

/// Shared geometry and static constants for QuanClash mobile v4.
///
/// Colors are resolved dynamically through [MobileV4Palette.of] so mobile v4
/// supports Light, Dark, and Follow System without touching desktop themes.
abstract final class MobileV4Theme {
  static const radiusCard = 18.0;
  static const radiusSheet = 28.0;

  static const bg = Color(0xFF000000);
  static const accent = Color(0xFFB9A2FF);
  static const signal = Color(0xFF8FD8A6);
  static const node = Color(0xFFF2C14E);
  static const warn = Color(0xFFD8A25E);
  static const danger = Color(0xFFD0716F);
}

/// Complete color palette for Mobile v4 in either Dark or Light brightness.
///
/// Dark mode matches `design/android-v4` (pure black + `#B9A2FF`); Light mode
/// aligns with the desktop light palette (`#F4F1FF -> #F2F2F7`, `#6C5CE7`,
/// pure white cards with soft lavender-grey elevation).
class MobileV4Palette {
  const MobileV4Palette({
    required this.isDark,
    required this.bg,
    required this.bgGradient,
    required this.sheet,
    required this.sheetTopBorder,
    required this.sheetBarrier,
    required this.sheetHandle,
    required this.sheetShadow,
    required this.cardFill,
    required this.cardShadow,
    required this.heroTopTint,
    required this.line,
    required this.lineSoft,
    required this.fill,
    required this.fill2,
    required this.iconBoxFill,
    required this.iconBoxBorder,
    required this.iconColor,
    required this.text,
    required this.text2,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.signal,
    required this.node,
    required this.warn,
    required this.danger,
    required this.barTrack,
    required this.switchOnTrack,
    required this.switchOnKnob,
    required this.switchOffTrack,
    required this.switchOffKnob,
    required this.importFill,
    required this.importBorder,
    required this.toastFill,
    required this.toastBorder,
    required this.toastText,
    required this.toastShadow,
    required this.menuScrimBase,
    required this.menuScrimMaxAlpha,
    required this.fabHubGradient,
    required this.fabHubBorder,
    required this.fabHubShadow,
    required this.fabMonogramRing,
    required this.fabMonogramText,
    required this.fabItemFill,
    required this.fabItemBorder,
    required this.fabItemIcon,
    required this.fabItemShadow,
    required this.closeBg,
    required this.closeBorder,
  });

  final bool isDark;
  final Color bg;
  final List<Color>? bgGradient;
  final Color sheet;
  final Color sheetTopBorder;
  final Color sheetBarrier;
  final Color sheetHandle;
  final Color sheetShadow;
  final Color cardFill;
  final Color cardShadow;
  final Color heroTopTint;
  final Color line;
  final Color lineSoft;
  final Color fill;
  final Color fill2;
  final Color iconBoxFill;
  final Color iconBoxBorder;
  final Color iconColor;
  final Color text;
  final Color text2;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color signal;
  final Color node;
  final Color warn;
  final Color danger;
  final Color barTrack;
  final Color switchOnTrack;
  final Color switchOnKnob;
  final Color switchOffTrack;
  final Color switchOffKnob;
  final Color importFill;
  final Color importBorder;
  final Color toastFill;
  final Color toastBorder;
  final Color toastText;
  final Color toastShadow;
  final Color menuScrimBase;
  final double menuScrimMaxAlpha;
  final List<Color> fabHubGradient;
  final Color fabHubBorder;
  final Color fabHubShadow;
  final Color fabMonogramRing;
  final Color fabMonogramText;
  final Color fabItemFill;
  final Color fabItemBorder;
  final Color fabItemIcon;
  final Color fabItemShadow;
  final Color closeBg;
  final Color closeBorder;

  TextStyle get wordmark => TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
    color: muted,
  );

  TextStyle get micro => TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: muted,
  );

  TextStyle get nodeTitle => TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.9,
    height: 1,
    color: text,
  );

  static const dark = MobileV4Palette(
    isDark: true,
    bg: Color(0xFF000000),
    bgGradient: null,
    sheet: Color(0xE60D0D10),
    sheetTopBorder: Color(0x1CFFFFFF),
    sheetBarrier: Color(0x8C000000),
    sheetHandle: Color(0x2EFFFFFF),
    sheetShadow: Color(0xBF000000),
    cardFill: Color(0x09FFFFFF),
    cardShadow: Colors.transparent,
    heroTopTint: Colors.transparent,
    line: Color(0x14FFFFFF),
    lineSoft: Color(0x0DFFFFFF),
    fill: Color(0x0EFFFFFF),
    fill2: Color(0x17FFFFFF),
    iconBoxFill: Color(0x0BFFFFFF),
    iconBoxBorder: Color(0x0DFFFFFF),
    iconColor: Color(0xFFD9D9DF),
    text: Color(0xFFF5F5F7),
    text2: Color(0xFFA6A6AE),
    muted: Color(0xFF6F6F78),
    faint: Color(0xFF46464E),
    accent: Color(0xFFB9A2FF),
    accentSoft: Color(0x1FB9A2FF),
    onAccent: Color(0xFF0A0A0B),
    signal: Color(0xFF8FD8A6),
    node: Color(0xFFF2C14E),
    warn: Color(0xFFD8A25E),
    danger: Color(0xFFD0716F),
    barTrack: Color(0x12FFFFFF),
    switchOnTrack: Color(0xFFF5F5F7),
    switchOnKnob: Color(0xFF0A0A0B),
    switchOffTrack: Color(0x17FFFFFF),
    switchOffKnob: Color(0xFFA6A6AE),
    importFill: Color(0x0DB9A2FF),
    importBorder: Color(0x47B9A2FF),
    toastFill: Color(0xD1141418),
    toastBorder: Color(0x1AFFFFFF),
    toastText: Color(0xFFE9E9EF),
    toastShadow: Color(0x99000000),
    menuScrimBase: Color(0xFF000000),
    menuScrimMaxAlpha: 0.42,
    fabHubGradient: [Color(0xD91B1B21), Color(0xE60B0B0E)],
    fabHubBorder: Color(0x21FFFFFF),
    fabHubShadow: Color(0xBF000000),
    fabMonogramRing: Color(0x94FFFFFF),
    fabMonogramText: Color(0xFFF2F2F4),
    fabItemFill: Color(0xBD121216),
    fabItemBorder: Color(0x1FFFFFFF),
    fabItemIcon: Color(0xFFA6A6AE),
    fabItemShadow: Color(0xD1000000),
    closeBg: Color(0x0EFFFFFF),
    closeBorder: Color(0x14FFFFFF),
  );

  static const light = MobileV4Palette(
    isDark: false,
    bg: Color(0xFFF5F5F8),
    bgGradient: [Color(0xFFF4F1FF), Color(0xFFF6F6FA), Color(0xFFF2F2F7)],
    sheet: Color(0xEBF5F5FA),
    sheetTopBorder: Color(0xF2FFFFFF),
    sheetBarrier: Color(0x38181626),
    sheetHandle: Color(0x26181622),
    sheetShadow: Color(0x2E564A80),
    cardFill: Color(0xFFFFFFFF),
    cardShadow: Color(0x17564A80),
    heroTopTint: Color(0x0F6C5CE7),
    line: Color(0x16181622),
    lineSoft: Color(0x0E181622),
    fill: Color(0x0B181622),
    fill2: Color(0x16181622),
    iconBoxFill: Color(0xFFF4F2FC),
    iconBoxBorder: Color(0x176C5CE7),
    iconColor: Color(0xFF342F52),
    text: Color(0xFF16161B),
    text2: Color(0xFF5A5A66),
    muted: Color(0xFF848490),
    faint: Color(0xFFA8A8B6),
    accent: Color(0xFF6C5CE7),
    accentSoft: Color(0x1A6C5CE7),
    onAccent: Color(0xFFFFFFFF),
    signal: Color(0xFF2E9C5C),
    node: Color(0xFFE5A01D),
    warn: Color(0xFFD97706),
    danger: Color(0xFFD94848),
    barTrack: Color(0x1C6C5CE7),
    switchOnTrack: Color(0xFF16161B),
    switchOnKnob: Color(0xFFFFFFFF),
    switchOffTrack: Color(0xFFE4E4EC),
    switchOffKnob: Color(0xFFFFFFFF),
    importFill: Color(0xFFF5F3FF),
    importBorder: Color(0x526C5CE7),
    toastFill: Color(0xE6FFFFFF),
    toastBorder: Color(0x1A564A80),
    toastText: Color(0xFF1C1C22),
    toastShadow: Color(0x38564A80),
    menuScrimBase: Color(0xFFF4F3FA),
    menuScrimMaxAlpha: 0.58,
    fabHubGradient: [Color(0xEBFFFFFF), Color(0xD6F3F1FC)],
    fabHubBorder: Color(0x20564A80),
    fabHubShadow: Color(0x47564A80),
    fabMonogramRing: Color(0x7316161B),
    fabMonogramText: Color(0xFF16161B),
    fabItemFill: Color(0xE6FFFFFF),
    fabItemBorder: Color(0x18564A80),
    fabItemIcon: Color(0xFF464652),
    fabItemShadow: Color(0x38564A80),
    closeBg: Color(0xE0FFFFFF),
    closeBorder: Color(0x12181622),
  );

  static MobileV4Palette of(BuildContext context) {
    return Theme.brightnessOf(context) == Brightness.dark ? dark : light;
  }
}

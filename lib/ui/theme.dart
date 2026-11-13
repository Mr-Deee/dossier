import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand: liquid glass. White, ink black and molten amber gold.
///
/// Legacy names (navy, ivory…) are kept so existing screens keep compiling;
/// they now map onto the new ink/amber palette.
class Brand {
  // Core palette
  static const ink = Color(0xFF0D0D0F);
  static const ink2 = Color(0xFF17171B);
  static const ink3 = Color(0xFF232329);
  static const amber = Color(0xFFF2B33D);
  static const amberDeep = Color(0xFFD48A0C);
  static const amberGlow = Color(0xFFFFD27A);
  static const pearl = Color(0xFFF4F3F0);
  static const mist = Color(0xFFE7E5E0);

  // Legacy aliases
  static const navy = ink;
  static const navy2 = ink2;
  static const navy3 = ink3;
  static const gold = amber;
  static const goldSoft = amberGlow;
  static const ivory = pearl;

  static const danger = Color(0xFFE5484D);
  static const ok = Color(0xFF30A46C);

  static const amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amberGlow, amber, amberDeep],
  );
}

/// Translucent "glass" colours for the current brightness.
class GlassColors {
  const GlassColors._(this.dark);
  final bool dark;

  static GlassColors of(BuildContext context) => GlassColors._(Theme.of(context).brightness == Brightness.dark);

  Color get fill => dark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.62);
  Color get fillStrong => dark ? Colors.white.withValues(alpha: 0.11) : Colors.white.withValues(alpha: 0.82);
  Color get border => dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.9);
  Color get hairline => dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
  Color get shadow => dark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF6B5A3A).withValues(alpha: 0.06);
  Color get muted => dark ? Colors.white.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.48);
  Color get base => dark ? const Color(0xFF09090B) : Brand.pearl;

  /// Amber reads too light on white for text, so use the deeper tone there.
  Color get accentText => dark ? Brand.amber : Brand.amberDeep;

  LinearGradient get sheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.035)]
            : [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.45)],
      );
}

final String? _font = GoogleFonts.outfit().fontFamily;

TextTheme _text(TextTheme base, Color on) {
  final t = base.apply(fontFamily: _font, bodyColor: on, displayColor: on);
  TextStyle? tight(TextStyle? s, {FontWeight w = FontWeight.w600, double ls = -0.5}) =>
      s?.copyWith(fontWeight: w, letterSpacing: ls, height: 1.08);
  return t.copyWith(
    displayLarge: tight(t.displayLarge, w: FontWeight.w700, ls: -1.5),
    displayMedium: tight(t.displayMedium, w: FontWeight.w700, ls: -1.2),
    displaySmall: tight(t.displaySmall, w: FontWeight.w700, ls: -1),
    headlineLarge: tight(t.headlineLarge, w: FontWeight.w700, ls: -0.8),
    headlineMedium: tight(t.headlineMedium, w: FontWeight.w700, ls: -0.6),
    headlineSmall: tight(t.headlineSmall, ls: -0.4),
    titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  );
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final glass = GlassColors._(dark);
  final on = dark ? const Color(0xFFF3F1EC) : Brand.ink;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? Brand.amber : Brand.ink,
    onPrimary: dark ? Brand.ink : Colors.white,
    primaryContainer: dark ? Brand.amber.withValues(alpha: 0.18) : Brand.amber.withValues(alpha: 0.22),
    onPrimaryContainer: on,
    secondary: dark ? Brand.amber : Brand.amberDeep,
    onSecondary: Brand.ink,
    secondaryContainer: Brand.amber.withValues(alpha: dark ? 0.2 : 0.28),
    onSecondaryContainer: on,
    tertiary: Brand.amber,
    onTertiary: Brand.ink,
    error: Brand.danger,
    onError: Colors.white,
    surface: dark ? const Color(0xFF111114) : const Color(0xFFF8F7F4),
    onSurface: on,
    onSurfaceVariant: glass.muted,
    surfaceContainerLowest: dark ? const Color(0xFF0C0C0E) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF151518) : const Color(0xFFFBFAF8),
    surfaceContainer: dark ? const Color(0xFF1A1A1E) : const Color(0xFFF2F0EC),
    surfaceContainerHigh: dark ? const Color(0xFF212126) : const Color(0xFFEBE9E4),
    surfaceContainerHighest: dark ? const Color(0xFF29292F) : const Color(0xFFE3E1DB),
    outline: dark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.14),
    outlineVariant: glass.hairline,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness, fontFamily: _font);
  final text = _text(base.textTheme, on);
  const pill = StadiumBorder();
  const transitions = _AmbientTransitions();

  return base.copyWith(
    textTheme: text,
    primaryTextTheme: _text(base.primaryTextTheme, on),
    // Pages paint their own ambient backdrop (see _AmbientTransitions).
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      for (final p in TargetPlatform.values) p: transitions,
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: on,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const Icon(CupertinoIcons.chevron_back, size: 20),
      closeButtonIconBuilder: (_) => const Icon(CupertinoIcons.xmark, size: 18),
      drawerButtonIconBuilder: (_) => const Icon(CupertinoIcons.line_horizontal_3, size: 20),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: glass.fill,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: glass.border),
      ),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      iconColor: on,
      titleTextStyle: text.titleSmall?.copyWith(fontSize: 15),
      subtitleTextStyle: text.bodySmall?.copyWith(color: glass.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glass.fillStrong,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: TextStyle(color: glass.muted),
      floatingLabelStyle: TextStyle(color: glass.accentText, fontWeight: FontWeight.w600),
      prefixIconColor: glass.muted,
      suffixIconColor: glass.muted,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: glass.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: glass.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Brand.amber, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Brand.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Brand.danger, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dark ? Brand.amber : Brand.ink,
        foregroundColor: dark ? Brand.ink : Colors.white,
        disabledBackgroundColor: on.withValues(alpha: 0.12),
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        shape: pill,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: glass.fillStrong,
        foregroundColor: on,
        elevation: 0,
        minimumSize: const Size(64, 52),
        shape: pill,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: on,
        backgroundColor: glass.fill,
        side: BorderSide(color: glass.border, width: 1.2),
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        shape: pill,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: glass.accentText,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        shape: pill,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Brand.amber,
      foregroundColor: Brand.ink,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: pill,
      extendedTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: glass.fillStrong,
      selectedColor: dark ? Brand.amber : Brand.ink,
      secondarySelectedColor: dark ? Brand.amber : Brand.ink,
      checkmarkColor: dark ? Brand.ink : Colors.white,
      labelStyle: text.labelLarge?.copyWith(color: on),
      secondaryLabelStyle: text.labelLarge?.copyWith(color: dark ? Brand.ink : Colors.white),
      side: BorderSide(color: glass.border),
      shape: pill,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? const Color(0xFF141417) : const Color(0xFFFAF9F7),
      surfaceTintColor: Colors.transparent,
      dragHandleColor: on.withValues(alpha: 0.2),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? const Color(0xFF16161A) : const Color(0xFFFBFAF8),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: dark ? const Color(0xFF0E0E11) : const Color(0xFFF7F6F3),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(32))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? const Color(0xFF26262B) : Brand.ink,
      contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
      actionTextColor: Brand.amber,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Brand.amber,
      linearTrackColor: on.withValues(alpha: 0.08),
      circularTrackColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.ink : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.amber : null),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.amber : null),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.amber : null),
      checkColor: const WidgetStatePropertyAll(Brand.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.amber : null),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: glass.fill,
        selectedBackgroundColor: dark ? Brand.amber : Brand.ink,
        selectedForegroundColor: dark ? Brand.ink : Colors.white,
        side: BorderSide(color: glass.border),
        shape: pill,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: on,
      unselectedLabelColor: glass.muted,
      indicatorColor: Brand.amber,
      dividerColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: glass.hairline, space: 24),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? const Color(0xFF1A1A1E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: Brand.amber.withValues(alpha: 0.3),
    ),
  );
}

/// Wraps every pushed page in the ambient backdrop so transparent scaffolds
/// stay opaque during transitions.
class _AmbientTransitions extends PageTransitionsBuilder {
  const _AmbientTransitions();
  static const _ios = CupertinoPageTransitionsBuilder();
  static const _android = FadeForwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final wrapped = AmbientBackground(child: child);
    final p = Theme.of(context).platform;
    final b = (p == TargetPlatform.iOS || p == TargetPlatform.macOS) ? _ios : _android;
    return b.buildTransitions(route, context, animation, secondaryAnimation, wrapped);
  }
}

/// Soft studio backdrop: a pearl (light) or near-black (dark) base with
/// blurred amber light pools, like a product shot.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child, this.intensity = 1});
  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final d = g.dark;
    Widget orb(Alignment a, double size, Color c, double alpha) => Align(
          alignment: a,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [c.withValues(alpha: alpha * intensity), c.withValues(alpha: 0)]),
            ),
          ),
        );
    return ColoredBox(
      color: g.base,
      child: Stack(fit: StackFit.expand, children: [
        IgnorePointer(
          child: RepaintBoundary(
            child: Stack(fit: StackFit.expand, children: [
              if (!d)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFBFAF7), Color(0xFFEDEBE6)],
                    ),
                  ),
                ),
              orb(const Alignment(1.4, -1.15), 520, d ? Brand.amberDeep : Brand.amberGlow, d ? 0.34 : 0.55),
              orb(const Alignment(-1.5, 0.15), 420, d ? const Color(0xFF6B4A12) : Colors.white, d ? 0.30 : 0.9),
              orb(const Alignment(0.9, 1.25), 460, d ? Brand.amber : const Color(0xFFFFE4B0), d ? 0.12 : 0.5),
            ]),
          ),
        ),
        child,
      ]),
    );
  }
}

/// Frosted glass panel with a hairline highlight edge.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.blur = 24,
    this.strong = false,
    this.onTap,
    this.color,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final bool strong;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final br = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (onTap != null) {
      content = InkWell(borderRadius: br, onTap: onTap, child: content);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [BoxShadow(color: g.shadow, blurRadius: 28, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                color: color,
                gradient: color == null
                    ? (strong
                        ? LinearGradient(colors: [g.fillStrong, g.fillStrong])
                        : g.sheen)
                    : null,
                borderRadius: br,
                border: Border.all(color: g.border, width: 1),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

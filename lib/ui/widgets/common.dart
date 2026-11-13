import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';

String fmtDate(DateTime? d) => d == null ? '—' : DateFormat.yMMMd().format(d);

String fmtDateStr(String? iso) => fmtDate(iso == null ? null : DateTime.tryParse(iso));

String fmtBytes(num bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Space a tab's FAB needs to clear the Shell's floating nav bar.
const double kShellNavClearance = 80;

/// The Shell's scaffold, so any tab can open the app drawer.
final shellScaffoldKey = GlobalKey<ScaffoldState>();

void toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? CupertinoIcons.exclamationmark_circle : CupertinoIcons.checkmark_circle,
            color: error ? Colors.white : Brand.amber, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: error ? Brand.danger : null,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
}

String friendlyError(Object e) {
  final s = e.toString();
  if (s.contains('permission-denied')) return 'Access denied. This information has not been released to you.';
  if (s.contains('network-request-failed') || s.contains('unavailable')) return 'Network unavailable. Check your connection.';
  if (s.contains('wrong-password') || s.contains('invalid-credential')) return 'Incorrect email or password.';
  if (s.contains('user-not-found')) return 'No account found for that email.';
  if (s.contains('email-already-in-use')) return 'An account already exists for that email.';
  if (s.contains('weak-password')) return 'Choose a stronger account password.';
  if (s.contains('requires-recent-login')) return 'Please sign out and sign in again, then retry.';
  return s.replaceFirst(RegExp(r'^(Exception|StateError|Bad state|CryptoError): ?'), '').replaceFirst('Bad state: ', '');
}

/// Runs [action] with a blocking progress overlay and friendly error toast.
Future<T?> runBusy<T>(BuildContext context, Future<T> Function() action, {String? success, String label = 'Working…'}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Glass(
          radius: 28,
          strong: true,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          child: Material(
            type: MaterialType.transparency,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, strokeCap: StrokeCap.round)),
              const SizedBox(width: 16),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: Text(label)),
            ]),
          ),
        ),
      ),
    ),
  );
  try {
    final r = await action();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      if (success != null) toast(context, success);
    }
    return r;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      toast(context, friendlyError(e), error: true);
    }
    return null;
  }
}

Future<bool> confirm(BuildContext context, String title, String message, {String ok = 'Confirm', bool destructive = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Brand.danger, foregroundColor: Colors.white, minimumSize: const Size(96, 48))
              : FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// The app icon (manila dossier folder with the "D" stamp).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.glow = false});
  final double size;
  final bool glow;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.24),
          boxShadow: [
            BoxShadow(
              color: (glow ? Brand.amber : Colors.black).withValues(alpha: glow ? 0.35 : 0.18),
              blurRadius: size * (glow ? 0.5 : 0.25),
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Image.asset('assets/brand/app_icon.png', width: size, height: size, filterQuality: FilterQuality.medium),
        ),
      );
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 28, this.showLogo = true});
  final double size;
  final bool showLogo;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (showLogo) ...[AppLogo(size: size * 1.45), SizedBox(width: size * 0.4)],
      Text('Dossier',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: size,
                fontWeight: FontWeight.w700,
                letterSpacing: -size * 0.04,
                color: c,
                height: 1,
              )),
    ]);
  }
}

/// Circular frosted icon button (header actions, back buttons).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, this.onPressed, this.tooltip, this.size = 48, this.badge = false});
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool badge;
  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: size,
      height: size,
      child: Glass(
        radius: size / 2,
        onTap: onPressed,
        child: Stack(children: [
          Center(child: Icon(icon, size: size * 0.42)),
          if (badge)
            Positioned(
              right: size * 0.26,
              top: size * 0.24,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Brand.amber, shape: BoxShape.circle),
              ),
            ),
        ]),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Opens the app drawer from any tab.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GlassIconButton(
            icon: CupertinoIcons.line_horizontal_3,
            size: 44,
            tooltip: 'Menu',
            onPressed: () => shellScaffoldKey.currentState?.openDrawer(),
          ),
        ),
      );
}

/// Large pill call-to-action with a trailing arrow bubble.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon = CupertinoIcons.arrow_up_right,
    this.busy = false,
    this.amber = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final useAmber = amber || dark;
    final bg = useAmber ? null : Brand.ink;
    final fg = useAmber ? Brand.ink : Colors.white;
    final enabled = onPressed != null && !busy;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || busy ? 1 : 0.45,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: bg,
          gradient: useAmber ? Brand.amberGradient : null,
          borderRadius: BorderRadius.circular(31),
          boxShadow: [
            BoxShadow(
              color: (useAmber ? Brand.amber : Brand.ink).withValues(alpha: useAmber ? 0.28 : 0.16),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(31),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 7, 7, 7),
              child: Row(children: [
                Expanded(
                  child: busy
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg)),
                        )
                      : Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: fg, fontWeight: FontWeight.w600, fontSize: 16.5)),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: useAmber ? Brand.ink.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, size: 20, color: useAmber ? Brand.amber : Colors.white),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(4, 26, 4, 12)});
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w600)),
          ),
          if (trailing != null)
            DefaultTextStyle.merge(
              style: TextStyle(color: GlassColors.of(context).muted, fontSize: 14),
              child: trailing!,
            ),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AmberOrb(icon: icon, size: 88),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: GlassColors.of(context).muted)),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}

/// Glowing amber sphere with an icon: the app's signature "object".
class AmberOrb extends StatelessWidget {
  const AmberOrb({super.key, required this.icon, this.size = 72});
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.35, -0.45),
            colors: [Brand.amberGlow, Brand.amber, Brand.amberDeep],
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(color: Brand.amber.withValues(alpha: 0.45), blurRadius: size * 0.5, offset: Offset(0, size * 0.15)),
          ],
        ),
        child: Icon(icon, color: Brand.ink, size: size * 0.42),
      );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner(this.text, {super.key, this.icon = CupertinoIcons.info, this.color});
  final String text;
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? Brand.amber;
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: color ?? GlassColors.of(context).accentText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
          ),
        ),
      ]),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.icon, this.onTap});
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Glass(
      onTap: onTap,
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null)
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Brand.amber, width: 1.6),
              ),
              child: Icon(icon, size: 19, color: g.accentText),
            ),
            const Spacer(),
            if (onTap != null) Icon(CupertinoIcons.arrow_up_right, size: 16, color: g.muted),
          ]),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6)),
        ),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: g.muted)),
      ]),
    );
  }
}

class NavTile extends StatelessWidget {
  const NavTile({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.trailing});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 22,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Brand.amber.withValues(alpha: 0.28), Brand.amber.withValues(alpha: 0.10)],
              ),
            ),
            child: Icon(icon, size: 22, color: g.accentText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: t.titleSmall?.copyWith(fontSize: 15.5), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: t.bodySmall?.copyWith(color: g.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          trailing ??
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle, color: g.hairline),
                child: Icon(CupertinoIcons.chevron_right, size: 14, color: g.muted),
              ),
        ]),
      ),
    );
  }
}

/// Semicircular amber gauge (readiness score etc).
class ArcGauge extends StatelessWidget {
  const ArcGauge({super.key, required this.value, required this.label, this.size = 200});
  final double value; // 0..1
  final String label;
  final double size;
  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return SizedBox(
      width: size,
      height: size * 0.62,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _ArcPainter(v, g.hairline, g.dark),
          child: Align(
            alignment: const Alignment(0, 0.75),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(v * 100).round()}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: size * 0.2)),
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: g.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.v, this.track, this.dark);
  final double v;
  final Color track;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final r = size.width / 2 - stroke / 2;
    final c = Offset(size.width / 2, size.width / 2);
    final rect = Rect.fromCircle(center: c, radius: r);
    const start = math.pi;
    const sweep = math.pi;
    // Dashed remainder, like a tick track.
    final tick = Paint()
      ..color = dark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    const n = 36;
    for (var i = 0; i < n; i++) {
      final a = start + sweep * i / n;
      if (a < start + sweep * v) continue;
      canvas.drawArc(rect, a, sweep / n * 0.45, false, tick);
    }
    if (v <= 0) return;
    final p = Paint()
      ..shader = const SweepGradient(
        startAngle: math.pi,
        endAngle: math.pi * 2,
        colors: [Brand.amberDeep, Brand.amber, Brand.amberGlow],
      ).createShader(rect)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, start, sweep * v, false, p);
    final end = Offset(c.dx + r * math.cos(start + sweep * v), c.dy + r * math.sin(start + sweep * v));
    canvas.drawCircle(end, stroke * 0.32, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.v != v || o.dark != dark;
}

class PassphraseStrength extends StatelessWidget {
  const PassphraseStrength(this.value, {super.key});
  final String value;

  static int score(String p) {
    var s = 0;
    if (p.length >= 12) s++;
    if (p.length >= 16) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p) || p.contains(' ')) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = score(value);
    final labels = ['Too weak', 'Weak', 'Fair', 'Good', 'Strong', 'Excellent'];
    final colors = [Brand.danger, Brand.danger, Colors.orange, Brand.amber, Brand.ok, Brand.ok];
    final g = GlassColors.of(context);
    return Row(children: [
      for (var i = 0; i < 5; i++)
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i < s ? colors[s] : g.hairline,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      const SizedBox(width: 8),
      SizedBox(
        width: 64,
        child: Text(labels[s], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: g.muted)),
      ),
    ]);
  }
}

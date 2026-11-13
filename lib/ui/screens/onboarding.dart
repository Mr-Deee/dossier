import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// First-launch introduction. Calls [onFinish] with `register: true` when the
/// person wants to create an account, `false` to sign in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinish, this.signedIn = false});
  final void Function({required bool register}) onFinish;

  /// Already signed in (first launch after an update, or replayed from
  /// Settings): finish simply continues instead of offering sign-up.
  final bool signedIn;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.eyebrow, this.title, this.body, this.visual);
  final String eyebrow;
  final String title;
  final String body;
  final Widget Function(double t) visual;
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  double _page = 0;

  late final _slides = <_Slide>[
    _Slide('Your life', 'Everything,\nin one place.',
        'Your records, assets, documents and wishes — organised beautifully and kept in one private dossier.',
        (t) => _CardsVisual(t: t)),
    _Slide('Private by design', 'Encrypted.\nOnly yours.',
        'Everything is encrypted on your device before it leaves. Not even we can read it.', (t) => _LockVisual(t: t)),
    _Slide('Your legacy', 'Your legacy,\nsecured.',
        'Choose trusted confidants who receive exactly what you decide — only when it\'s time.',
        (t) => _LegacyVisual(t: t)),
    _Slide('On your timing', 'Right words,\nright time.',
        'Schedule each message — the day access is released, months later, or on a date that matters to them.',
        (t) => _TimingVisual(t: t)),
  ];

  @override
  void initState() {
    super.initState();
    _pages.addListener(() => setState(() => _page = _pages.page ?? 0));
  }

  @override
  void dispose() {
    _pages.dispose();
    _float.dispose();
    super.dispose();
  }

  bool get _last => _page.round() == _slides.length - 1;

  void _next() {
    if (_last) {
      widget.onFinish(register: !widget.signedIn);
    } else {
      _pages.nextPage(duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = GlassColors.of(context);
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
            child: Row(children: [
              const Wordmark(size: 22),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _last ? 0 : 1,
                child: Glass(
                  radius: 22,
                  onTap: _last ? null : () => widget.onFinish(register: false),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text('Skip', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _slides.length,
              itemBuilder: (context, i) {
                final s = _slides[i];
                final delta = (_page - i).clamp(-1.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(delta * size.width * 0.35, 0),
                        child: Opacity(
                          opacity: (1 - delta.abs()).clamp(0, 1),
                          child: AnimatedBuilder(
                            animation: _float,
                            builder: (_, __) => Center(child: FittedBox(fit: BoxFit.scaleDown, child: s.visual(_float.value))),
                          ),
                        ),
                      ),
                    ),
                    Row(children: [
                      Container(
                          width: 8, height: 8, decoration: const BoxDecoration(color: Brand.amber, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(s.eyebrow, style: t.labelLarge?.copyWith(color: g.accentText, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 12),
                    Text(s.title, style: t.displayMedium?.copyWith(fontSize: size.height < 700 ? 40 : 48)),
                    const SizedBox(height: 14),
                    Text(s.body, style: t.bodyLarge?.copyWith(color: g.muted, height: 1.45)),
                  ]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            child: Row(children: [
              for (var i = 0; i < _slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 6),
                  width: (_page.round() == i) ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: _page.round() == i ? Brand.amberGradient : null,
                    color: _page.round() == i ? null : g.hairline,
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
            child: Row(children: [
              if (!widget.signedIn) ...[
                GlassIconButton(
                  icon: _last ? CupertinoIcons.person_crop_circle : CupertinoIcons.lock_shield,
                  size: 62,
                  tooltip: 'I already have an account',
                  onPressed: () => widget.onFinish(register: false),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: PillButton(
                  label: _last ? (widget.signedIn ? 'Let\'s go' : 'Get started') : 'Continue',
                  icon: _last ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_right,
                  onPressed: _next,
                ),
              ),
            ]),
          ),
          SizedBox(
            height: 44,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _last && !widget.signedIn ? 1 : 0,
              child: TextButton(
                onPressed: _last && !widget.signedIn ? () => widget.onFinish(register: false) : null,
                child: const Text('I already have an account'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

double _bob(double t, [double phase = 0, double amp = 8]) => math.sin((t + phase) * 2 * math.pi) * amp;

// ---- Visuals ---------------------------------------------------------------

class _CardsVisual extends StatelessWidget {
  const _CardsVisual({required this.t});
  final double t;
  @override
  Widget build(BuildContext context) {
    Widget card(String title, String sub, IconData icon, double angle, Offset o, double phase, {bool front = false}) =>
        Transform.translate(
          offset: o + Offset(0, _bob(t, phase)),
          child: Transform.rotate(
            angle: angle,
            child: SizedBox(
              width: 210,
              height: 138,
              child: front
                  ? Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Brand.ink,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 18)),
                        ],
                      ),
                      child: _cardBody(context, title, sub, icon, onInk: true),
                    )
                  : Glass(radius: 28, strong: true, padding: const EdgeInsets.all(18), child: _cardBody(context, title, sub, icon)),
            ),
          ),
        );
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(alignment: Alignment.center, children: [
        _Glow(size: 300, dy: _bob(t, 0.2, 6)),
        card('Wealth', '12 assets', CupertinoIcons.chart_pie_fill, -0.20, const Offset(-28, -86), 0.0),
        card('Vault', '48 documents', CupertinoIcons.lock_shield_fill, 0.16, const Offset(30, -6), 0.33),
        card('Life', 'Profile complete', CupertinoIcons.person_fill, -0.05, const Offset(-10, 84), 0.66, front: true),
      ]),
    );
  }

  Widget _cardBody(BuildContext context, String title, String sub, IconData icon, {bool onInk = false}) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: onInk ? Brand.amberGradient : null,
            color: onInk ? null : Brand.amber.withValues(alpha: 0.22),
          ),
          child: Icon(icon, size: 18, color: onInk ? Brand.ink : GlassColors.of(context).accentText),
        ),
        const Spacer(),
        Icon(CupertinoIcons.arrow_up_right, size: 16, color: onInk ? Colors.white54 : GlassColors.of(context).muted),
      ]),
      const Spacer(),
      Text(title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: onInk ? Colors.white : null)),
      Text(sub, style: tt.bodySmall?.copyWith(color: onInk ? Colors.white60 : GlassColors.of(context).muted)),
    ]);
  }
}

class _LockVisual extends StatelessWidget {
  const _LockVisual({required this.t});
  final double t;
  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    Widget ring(double s, double a) => Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: (g.dark ? Colors.white : Brand.ink).withValues(alpha: a)),
          ),
        );
    Widget chip(String label, IconData icon, Offset o, double phase) => Transform.translate(
          offset: o + Offset(0, _bob(t, phase, 6)),
          child: Glass(
            radius: 22,
            strong: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: g.accentText),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            ]),
          ),
        );
    return SizedBox(
      width: 330,
      height: 330,
      child: Stack(alignment: Alignment.center, children: [
        const _Glow(size: 320, dy: 0),
        Transform.rotate(angle: t * 2 * math.pi, child: _DashedRing(size: 300, color: g.muted.withValues(alpha: 0.35))),
        ring(230, 0.08),
        ring(170, 0.12),
        Transform.translate(offset: Offset(0, _bob(t, 0, 5)), child: const AmberOrb(icon: CupertinoIcons.lock_fill, size: 116)),
        chip('AES-256', CupertinoIcons.checkmark_shield_fill, const Offset(-92, -118), 0.1),
        chip('Zero-knowledge', CupertinoIcons.eye_slash_fill, const Offset(70, 112), 0.55),
        chip('On-device', CupertinoIcons.device_phone_portrait, const Offset(92, -40), 0.8),
      ]),
    );
  }
}

class _LegacyVisual extends StatelessWidget {
  const _LegacyVisual({required this.t});
  final double t;
  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final tt = Theme.of(context).textTheme;
    Widget avatar(String s, Color c) => Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
            border: Border.all(color: g.dark ? Brand.ink : Colors.white, width: 2.5),
          ),
          child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.ink)),
        );
    return SizedBox(
      width: 330,
      height: 330,
      child: Stack(alignment: Alignment.center, children: [
        _Glow(size: 320, dy: _bob(t, 0.3, 6)),
        Transform.translate(
          offset: Offset(0, _bob(t, 0, 6)),
          child: SizedBox(
            width: 270,
            child: Glass(
              radius: 32,
              strong: true,
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Trusted confidants', style: tt.titleMedium),
                const SizedBox(height: 4),
                Text('Released only when verified', style: tt.bodySmall?.copyWith(color: g.muted)),
                const SizedBox(height: 16),
                Row(children: [
                  for (final a in [
                    ('A', Brand.amberGlow),
                    ('K', Brand.amber),
                    ('E', const Color(0xFFF5D9A8)),
                    ('M', Brand.amberDeep),
                  ])
                    Align(widthFactor: 0.72, alignment: Alignment.centerLeft, child: avatar(a.$1, a.$2)),
                  const SizedBox(width: 18),
                  Flexible(
                    child: Text('+2 more',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelMedium?.copyWith(color: g.muted)),
                  ),
                ]),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(children: [
                    Container(height: 10, color: g.hairline),
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Container(height: 10, decoration: const BoxDecoration(gradient: Brand.amberGradient)),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Text('Legacy readiness',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: g.muted)),
                  ),
                  Text('80%', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(108, -128 + _bob(t, 0.5, 7)),
          child: const AmberOrb(icon: CupertinoIcons.envelope_fill, size: 64),
        ),
        Transform.translate(
          offset: Offset(-88, 124 + _bob(t, 0.2, 5)),
          child: Glass(
            radius: 22,
            strong: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.heart_fill, size: 15, color: g.accentText),
              const SizedBox(width: 6),
              Text('Life Check', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TimingVisual extends StatelessWidget {
  const _TimingVisual({required this.t});
  final double t;
  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final tt = Theme.of(context).textTheme;
    Widget row(IconData icon, String title, String when, {bool active = false}) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active ? Brand.amberGradient : null,
                color: active ? null : Brand.amber.withValues(alpha: 0.18),
              ),
              child: Icon(icon, size: 17, color: active ? Brand.ink : g.accentText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text(when, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelSmall?.copyWith(color: g.muted)),
              ]),
            ),
          ]),
        );
    return SizedBox(
      width: 330,
      height: 330,
      child: Stack(alignment: Alignment.center, children: [
        _Glow(size: 320, dy: _bob(t, 0.1, 6)),
        Transform.translate(
          offset: Offset(0, 10 + _bob(t, 0, 6)),
          child: SizedBox(
            width: 268,
            child: Glass(
              radius: 32,
              strong: true,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Succession messages', style: tt.titleMedium),
                row(CupertinoIcons.bolt_fill, 'To my family', 'When access is released', active: true),
                row(CupertinoIcons.hourglass, 'For Kofi', '6 months after release'),
                row(CupertinoIcons.gift_fill, 'For Ama', 'Opens 14 Mar 2034'),
              ]),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(106, -126 + _bob(t, 0.45, 7)),
          child: const AmberOrb(icon: CupertinoIcons.calendar, size: 64),
        ),
      ]),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.dy});
  final double size;
  final double dy;
  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: Offset(0, dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              Brand.amber.withValues(alpha: GlassColors.of(context).dark ? 0.35 : 0.45),
              Brand.amber.withValues(alpha: 0),
            ]),
          ),
        ),
      );
}

class _DashedRing extends StatelessWidget {
  const _DashedRing({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _DashedRingPainter(color));
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    const n = 60;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect.deflate(1), 2 * math.pi * i / n, 2 * math.pi / n * 0.4, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter o) => o.color != color;
}

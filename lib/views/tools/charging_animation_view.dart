import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class ChargingAnimationView extends StatefulWidget {
  const ChargingAnimationView({super.key});

  @override
  State<ChargingAnimationView> createState() => _ChargingAnimationViewState();
}

class _ChargingAnimationViewState extends State<ChargingAnimationView> with TickerProviderStateMixin {
  int _selectedStyle = 0;
  late AnimationController _anim;
  final double _battery = 0.72;

  static final _styles = [
    ('波浪', Icons.waves_rounded, Color(0xFF3B82F6)),
    ('脈衝', Icons.radio_button_checked_rounded, Color(0xFF10B981)),
    ('光環', Icons.blur_circular_rounded, Color(0xFF8B5CF6)),
    ('漸層', Icons.gradient_rounded, Color(0xFFEC4899)),
    ('粒子', Icons.grain_rounded, Color(0xFF06B6D4)),
    ('閃電', Icons.bolt_rounded, Color(0xFFEAB308)),
    ('DNA', Icons.gesture_rounded, Color(0xFFEF4444)),
    ('矩陣', Icons.grid_4x4_rounded, Color(0xFF22D3EE)),
    ('極光', Icons.auto_awesome_rounded, Color(0xFF6366F1)),
    ('火焰', Icons.local_fire_department_rounded, Color(0xFFF97316)),
    ('雷達', Icons.radar_rounded, Color(0xFF14B8A6)),
    ('星空', Icons.star_rounded, Color(0xFFA855F7)),
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(title: const Text('充電動畫')),
      body: Column(children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: _styles[_selectedStyle].$3.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(children: [
                AnimatedBuilder(animation: _anim, builder: (_, child) =>
                    CustomPaint(size: Size.infinite, painter: _getPainter(_selectedStyle, _anim.value, _battery))),
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(_battery * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -2)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bolt_rounded, color: _styles[_selectedStyle].$3, size: 14),
                      const SizedBox(width: 4),
                      Text('充電中', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ])),
              ]),
            ),
          ),
        ),
        SizedBox(height: 170, child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.8),
          itemCount: _styles.length,
          itemBuilder: (ctx, i) {
            final sel = _selectedStyle == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedStyle = i),
              child: Container(
                decoration: BoxDecoration(
                  color: sel ? _styles[i].$3.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: sel ? _styles[i].$3 : Colors.grey.withValues(alpha: 0.1), width: sel ? 2 : 1)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_styles[i].$2, color: sel ? _styles[i].$3 : AppTheme.textMuted, size: 24),
                  const SizedBox(height: 6),
                  Text(_styles[i].$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? _styles[i].$3 : AppTheme.textMuted)),
                ]),
              ),
            );
          },
        )),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [_styles[_selectedStyle].$3, _styles[_selectedStyle].$3.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(50), boxShadow: [AppTheme.colorShadow(_styles[_selectedStyle].$3)]),
          child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(50),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已設定「${_styles[_selectedStyle].$1}」充電動畫'),
                behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            child: const Center(child: Text('設定動畫', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))))),
        )),
        const SizedBox(height: 24),
      ]),
    );
  }

  CustomPainter _getPainter(int i, double p, double l) => switch (i) {
    0 => _WavePainter(p, l), 1 => _PulsePainter(p, l), 2 => _RingsPainter(p, l),
    3 => _GradientPainter(p, l), 4 => _ParticlePainter(p, l, Colors.cyan),
    5 => _LightningPainter(p, l), 6 => _DNAPainter(p, l), 7 => _MatrixPainter(p, l),
    8 => _AuroraPainter(p, l), 9 => _FirePainter(p, l), 10 => _RadarPainter(p, l),
    11 => _StarfieldPainter(p, l), _ => _WavePainter(p, l),
  };
}

class _WavePainter extends CustomPainter {
  final double p, l; _WavePainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    for (int w = 0; w < 3; w++) {
      final wy = s.height * (1 - l) + w * 8;
      final path = Path()..moveTo(0, s.height);
      for (double x = 0; x <= s.width; x += 2) {
        path.lineTo(x, wy + sin((x / s.width + p + w * 0.3) * pi * 2) * (10 - w * 2));
      }
      path.lineTo(s.width, s.height); path.close();
      c.drawPath(path, Paint()..color = Colors.blue.withValues(alpha: 0.3 - w * 0.08));
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _PulsePainter extends CustomPainter {
  final double p, l; _PulsePainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    final ct = Offset(s.width / 2, s.height / 2);
    for (int i = 0; i < 5; i++) { final r = 30.0 + ((p + i * 0.2) % 1.0) * 140;
      c.drawCircle(ct, r, Paint()..color = Colors.greenAccent.withValues(alpha: (1 - (p + i * 0.2) % 1.0) * 0.35)..style = PaintingStyle.stroke..strokeWidth = 2.5); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _RingsPainter extends CustomPainter {
  final double p, l; _RingsPainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    final ct = Offset(s.width / 2, s.height / 2);
    for (int i = 0; i < 6; i++) { c.save(); c.translate(ct.dx, ct.dy);
      c.rotate(p * pi * 2 * (i.isEven ? 1 : -1) + i * 0.8); c.translate(-ct.dx, -ct.dy);
      c.drawArc(Rect.fromCircle(center: ct, radius: 25.0 + i * 22), 0, pi * 2 * l * 0.7, false, Paint()
        ..color = HSLColor.fromAHSL(0.5 - i * 0.06, 260 + i * 20.0, 0.8, 0.65).toColor()..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
      c.restore(); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _GradientPainter extends CustomPainter {
  final double p, l; _GradientPainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment(0, -(l * 2 - 1)),
      colors: [HSLColor.fromAHSL(1, p * 360, 0.9, 0.55).toColor(), HSLColor.fromAHSL(1, (p * 360 + 80) % 360, 0.8, 0.45).toColor(), Colors.black])
        .createShader(Rect.fromLTWH(0, 0, s.width, s.height)));
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _ParticlePainter extends CustomPainter {
  final double p, l; final Color color; _ParticlePainter(this.p, this.l, this.color);
  @override void paint(Canvas c, Size s) {
    final rng = Random(42);
    for (int i = 0; i < 60; i++) { final x = rng.nextDouble() * s.width; final sp = 0.5 + rng.nextDouble() * 1.5;
      final y = (s.height + 20 - (p * sp * s.height + rng.nextDouble() * s.height)) % (s.height + 20);
      c.drawCircle(Offset(x, y), 1.5 + rng.nextDouble() * 3, Paint()..color = color.withValues(alpha: 0.2 + rng.nextDouble() * 0.5)); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _LightningPainter extends CustomPainter {
  final double p, l; _LightningPainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    final rng = Random((p * 10).toInt());
    for (int b = 0; b < 3; b++) { final path = Path(); double x = s.width * (0.3 + rng.nextDouble() * 0.4); double y = 0; path.moveTo(x, y);
      while (y < s.height * l) { x += (rng.nextDouble() - 0.5) * 40; y += 15 + rng.nextDouble() * 25; path.lineTo(x, y); }
      c.drawPath(path, Paint()..color = Colors.yellowAccent.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
      c.drawPath(path, Paint()..color = Colors.yellow.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 8..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _DNAPainter extends CustomPainter {
  final double p, l; _DNAPainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    for (double y = 0; y < s.height; y += 4) { final t = y / s.height * pi * 4 + p * pi * 2;
      c.drawCircle(Offset(cx + sin(t) * 50, y), 3, Paint()..color = Colors.red.withValues(alpha: 0.6));
      c.drawCircle(Offset(cx - sin(t) * 50, y), 3, Paint()..color = Colors.blue.withValues(alpha: 0.6));
      if ((y / 4).toInt() % 6 == 0) c.drawLine(Offset(cx + sin(t) * 50, y), Offset(cx - sin(t) * 50, y), Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 1); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _MatrixPainter extends CustomPainter {
  final double p, l; _MatrixPainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    final rng = Random(99); const chars = '01アイウエオカキクケコ'; final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int col = 0; col < 20; col++) { final x = col * (s.width / 20); final sp = 0.3 + rng.nextDouble() * 0.7; final off = rng.nextDouble() * s.height;
      for (int row = 0; row < 15; row++) { final y = (off + row * 18 + p * sp * s.height) % s.height;
        tp.text = TextSpan(text: chars[rng.nextInt(chars.length)], style: TextStyle(color: Colors.green.withValues(alpha: (1 - row / 15) * 0.7), fontSize: 12));
        tp.layout(); tp.paint(c, Offset(x, y)); } }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _AuroraPainter extends CustomPainter {
  final double p, l; _AuroraPainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    for (int i = 0; i < 5; i++) { final path = Path()..moveTo(0, s.height * (0.3 + i * 0.1));
      for (double x = 0; x <= s.width; x += 4) {
        path.lineTo(x, s.height * (0.3 + i * 0.1) + sin(x / 60 + p * pi * 2 + i) * 40 + cos(x / 30 + p * pi * 3) * 20);
      }
      path.lineTo(s.width, s.height); path.lineTo(0, s.height); path.close();
      c.drawPath(path, Paint()..color = HSLColor.fromAHSL(0.12, 200 + i * 30 + p * 60, 0.9, 0.6).toColor()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _FirePainter extends CustomPainter {
  final double p, l; _FirePainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    final rng = Random(7); final ft = s.height * (1 - l);
    for (int i = 0; i < 80; i++) { final x = rng.nextDouble() * s.width; final mH = s.height - ft;
      final h = rng.nextDouble() * mH; final y = s.height - h * ((p * 2 + rng.nextDouble()) % 1.0);
      final r = 3.0 + rng.nextDouble() * 6; final ratio = 1 - h / mH;
      c.drawCircle(Offset(x, y), r, Paint()..color = Color.lerp(Colors.yellow, Colors.red.shade900, ratio)!.withValues(alpha: 0.3 + rng.nextDouble() * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _RadarPainter extends CustomPainter {
  final double p, l; _RadarPainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    final ct = Offset(s.width / 2, s.height / 2);
    for (int i = 1; i <= 4; i++) {
      c.drawCircle(ct, i * 35.0, Paint()..color = Colors.teal.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    c.drawLine(Offset(ct.dx, 0), Offset(ct.dx, s.height), Paint()..color = Colors.teal.withValues(alpha: 0.1)..strokeWidth = 1);
    c.drawLine(Offset(0, ct.dy), Offset(s.width, ct.dy), Paint()..color = Colors.teal.withValues(alpha: 0.1)..strokeWidth = 1);
    final a = p * pi * 2; c.drawLine(ct, Offset(ct.dx + cos(a) * 140, ct.dy + sin(a) * 140), Paint()..color = Colors.tealAccent.withValues(alpha: 0.7)..strokeWidth = 1.5);
    final sp = Path()..moveTo(ct.dx, ct.dy)..arcTo(Rect.fromCircle(center: ct, radius: 140), a - 0.5, 0.5, false)..close();
    c.drawPath(sp, Paint()..shader = RadialGradient(colors: [Colors.tealAccent.withValues(alpha: 0.4), Colors.transparent]).createShader(Rect.fromCircle(center: ct, radius: 140)));
    final rng = Random(42); for (int i = 0; i < 8; i++) { final da = rng.nextDouble() * pi * 2; final dr = 30 + rng.nextDouble() * 100;
      c.drawCircle(Offset(ct.dx + cos(da) * dr, ct.dy + sin(da) * dr), 3, Paint()..color = Colors.tealAccent.withValues(alpha: 0.5 + rng.nextDouble() * 0.5)); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
class _StarfieldPainter extends CustomPainter {
  final double p, l; _StarfieldPainter(this.p, this.l);
  @override void paint(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2; final rng = Random(123);
    for (int i = 0; i < 100; i++) { final a = rng.nextDouble() * pi * 2; final sp = 0.2 + rng.nextDouble() * 0.8;
      final d = ((p * sp + rng.nextDouble()) % 1.0) * s.width * 0.7; final r = 0.5 + (d / s.width) * 3;
      c.drawCircle(Offset(cx + cos(a) * d, cy + sin(a) * d), r, Paint()..color = Colors.white.withValues(alpha: (d / s.width * 1.5).clamp(0, 1) * 0.8)); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}

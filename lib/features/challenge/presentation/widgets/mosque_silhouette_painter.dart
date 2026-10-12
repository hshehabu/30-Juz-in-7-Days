import 'package:flutter/material.dart';

/// Paints an authentic, gracefully proportioned Islamic mosque skyline.
/// Features a majestic grand central dome with a crescent finial (hilal),
/// flanked by stepped semi-domes and slender, authentic minarets with balconies
/// and conical spires, plus a soft atmospheric background skyline.
class MosqueSilhouettePainter extends CustomPainter {
  final Color color;

  const MosqueSilhouettePainter({
    this.color = const Color(0xFFDFD7C2),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Distant background layer (light silhouette for atmospheric depth)
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    // Foreground main mosque layer
    final fgPaint = Paint()
      ..color = color.withValues(alpha: 0.68)
      ..style = PaintingStyle.fill;

    // Soft architectural accent paint (for arched windows / openings)
    final windowCutoutPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // ── 1. Distant Background Layer: Distant Minaret & Soft Side Domes ───────
    final bgPath = Path();
    bgPath.moveTo(w * 0.02, h);

    // Distant slim minaret far left
    _drawMinaretShaft(
      bgPath,
      cx: w * 0.12,
      baseY: h,
      topY: h * 0.22,
      shaftWidth: w * 0.028,
      hasUpperBalcony: false,
    );

    // Distant soft dome
    final bDomeCx = w * 0.32;
    final bDomeW = w * 0.24;
    final bDomeFloor = h * 0.72;
    final bDomeApex = h * 0.40;
    bgPath.lineTo(bDomeCx - bDomeW * 0.5, h);
    bgPath.lineTo(bDomeCx - bDomeW * 0.5, bDomeFloor);
    _drawDomeCurve(
      bgPath,
      cx: bDomeCx,
      floorY: bDomeFloor,
      apexY: bDomeApex,
      halfWidth: bDomeW * 0.5,
      flared: true,
    );
    bgPath.lineTo(bDomeCx + bDomeW * 0.5, h);

    // Distant slim minaret on the far right
    _drawMinaretShaft(
      bgPath,
      cx: w * 0.94,
      baseY: h,
      topY: h * 0.18,
      shaftWidth: w * 0.025,
      hasUpperBalcony: false,
    );

    bgPath.lineTo(w, h);
    bgPath.close();
    canvas.drawPath(bgPath, bgPaint);

    // ── 2. Foreground Layer: Majestic Grand Mosque ───────────────────────────
    final fgPath = Path();
    fgPath.moveTo(0, h);

    // Base ground wall (rests naturally on the bottom)
    const baseWallYFactor = 0.82;
    final baseWallY = h * baseWallYFactor;

    fgPath.lineTo(0, baseWallY);

    // --- Left Minaret (Slender, authentic Ottoman proportions) ---
    final lMinCx = w * 0.22;
    final minShaftW = w * 0.038;
    fgPath.lineTo(lMinCx - minShaftW * 0.9, baseWallY);
    _drawMinaretShaft(
      fgPath,
      cx: lMinCx,
      baseY: baseWallY,
      topY: h * 0.08,
      shaftWidth: minShaftW,
      hasUpperBalcony: true,
    );
    fgPath.lineTo(lMinCx + minShaftW * 0.9, baseWallY);

    // --- Left Transition Wall & Semi-Dome ---
    final lDomeCx = w * 0.38;
    final lDomeW = w * 0.22;
    final lDomeFloor = h * 0.68;
    final lDomeApex = h * 0.42;

    fgPath.lineTo(lDomeCx - lDomeW * 0.5, baseWallY);
    fgPath.lineTo(lDomeCx - lDomeW * 0.5, lDomeFloor);
    _drawDomeCurve(
      fgPath,
      cx: lDomeCx,
      floorY: lDomeFloor,
      apexY: lDomeApex,
      halfWidth: lDomeW * 0.5,
      flared: true,
    );
    fgPath.lineTo(lDomeCx + lDomeW * 0.5, baseWallY);

    // --- Grand Central Dome (Majestic, generous, perfectly curved) ---
    final mainDomeCx = w * 0.62;
    final mainDomeW = w * 0.40;
    final mainDomeFloor = h * 0.60;
    final mainDomeApex = h * 0.16;

    // Dome base drum (straight vertical walls with decorative arches)
    fgPath.lineTo(mainDomeCx - mainDomeW * 0.5, baseWallY);
    fgPath.lineTo(mainDomeCx - mainDomeW * 0.5, mainDomeFloor);

    // Beautiful classical Islamic dome curve
    _drawDomeCurve(
      fgPath,
      cx: mainDomeCx,
      floorY: mainDomeFloor,
      apexY: mainDomeApex,
      halfWidth: mainDomeW * 0.5,
      flared: true,
    );
    fgPath.lineTo(mainDomeCx + mainDomeW * 0.5, mainDomeFloor);
    fgPath.lineTo(mainDomeCx + mainDomeW * 0.5, baseWallY);

    // --- Right Minaret (Slender, authentic, tall) ---
    final rMinCx = w * 0.86;
    fgPath.lineTo(rMinCx - minShaftW * 0.9, baseWallY);
    _drawMinaretShaft(
      fgPath,
      cx: rMinCx,
      baseY: baseWallY,
      topY: h * 0.06,
      shaftWidth: minShaftW,
      hasUpperBalcony: true,
    );
    fgPath.lineTo(rMinCx + minShaftW * 0.9, baseWallY);

    // Connect along base wall to right edge and close
    fgPath.lineTo(w, baseWallY);
    fgPath.lineTo(w, h);
    fgPath.close();

    canvas.drawPath(fgPath, fgPaint);

    // ── 3. Crescent Finials (Hilal) atop Minarets and Main Dome ──────────────
    // Main Dome Crescent (Grand brass hilal)
    _drawHilalFinial(canvas, mainDomeCx, mainDomeApex, size: h * 0.07, paint: fgPaint);
    // Left Minaret Crescent
    _drawHilalFinial(canvas, lMinCx, h * 0.08, size: h * 0.045, paint: fgPaint);
    // Right Minaret Crescent
    _drawHilalFinial(canvas, rMinCx, h * 0.06, size: h * 0.045, paint: fgPaint);

    // ── 4. Architectural Cutouts: Arched Windows in Drum & Walls ─────────────
    // Drum arched windows under the main dome
    _drawArchedWindowRow(
      canvas,
      cx: mainDomeCx,
      y: mainDomeFloor + (baseWallY - mainDomeFloor) * 0.28,
      width: w * 0.038,
      height: h * 0.10,
      count: 3,
      spacing: w * 0.055,
      paint: windowCutoutPaint,
    );

    // Arched portal in left wall
    _drawArchedWindow(
      canvas,
      cx: lDomeCx,
      y: lDomeFloor + (baseWallY - lDomeFloor) * 0.32,
      width: w * 0.042,
      height: h * 0.09,
      paint: windowCutoutPaint,
    );

    // ── 5. Elegant Crescent Moon & Subtle Sparkles in the Sky ────────────────
    _drawSkyCrescent(
      canvas,
      cx: w * 0.38,
      cy: h * 0.16,
      radius: h * 0.09,
      paint: color.withValues(alpha: 0.65),
    );

    _drawStar(canvas, cx: w * 0.46, cy: h * 0.10, radius: 2.2, color: color.withValues(alpha: 0.55));
    _drawStar(canvas, cx: w * 0.12, cy: h * 0.14, radius: 1.8, color: color.withValues(alpha: 0.45));
    _drawStar(canvas, cx: w * 0.74, cy: h * 0.08, radius: 2.0, color: color.withValues(alpha: 0.50));
  }

  /// Draws a classic Islamic dome curve into [path].
  /// Smoothly starts near floor, slightly swells (onion shape), then converges gracefully to pointed apex.
  static void _drawDomeCurve(
    Path path, {
    required double cx,
    required double floorY,
    required double apexY,
    required double halfWidth,
    required bool flared,
  }) {
    final domeH = floorY - apexY;
    final leftX = cx - halfWidth;
    final rightX = cx + halfWidth;

    // Left half curve
    path.cubicTo(
      leftX - (flared ? halfWidth * 0.08 : 0.0),
      floorY - domeH * 0.45,
      cx - halfWidth * 0.45,
      apexY + domeH * 0.12,
      cx,
      apexY,
    );

    // Right half curve
    path.cubicTo(
      cx + halfWidth * 0.45,
      apexY + domeH * 0.12,
      rightX + (flared ? halfWidth * 0.08 : 0.0),
      floorY - domeH * 0.45,
      rightX,
      floorY,
    );
  }

  /// Draws an authentic minaret shaft with pedestal, balcony (sherefe), upper shaft,
  /// and conical pointed cap (kulah).
  static void _drawMinaretShaft(
    Path path, {
    required double cx,
    required double baseY,
    required double topY,
    required double shaftWidth,
    required bool hasUpperBalcony,
  }) {
    final halfW = shaftWidth / 2;
    final totalH = baseY - topY;

    // Pedestal base
    path.lineTo(cx - halfW * 1.25, baseY);
    final pedY = baseY - totalH * 0.08;
    path.lineTo(cx - halfW * 1.1, pedY);

    // Lower shaft
    final lowerBalconyY = baseY - totalH * 0.52;
    path.lineTo(cx - halfW * 0.9, lowerBalconyY);

    // Lower Balcony (Sherefe) with decorative corbel overhang
    path.lineTo(cx - halfW * 1.45, lowerBalconyY);
    path.lineTo(cx - halfW * 1.45, lowerBalconyY - totalH * 0.04);
    path.lineTo(cx - halfW * 0.8, lowerBalconyY - totalH * 0.04);

    // Upper shaft (slightly narrower)
    final upperBalconyY = baseY - totalH * 0.76;
    if (hasUpperBalcony) {
      path.lineTo(cx - halfW * 0.75, upperBalconyY);
      // Upper balcony
      path.lineTo(cx - halfW * 1.25, upperBalconyY);
      path.lineTo(cx - halfW * 1.25, upperBalconyY - totalH * 0.035);
      path.lineTo(cx - halfW * 0.65, upperBalconyY - totalH * 0.035);
    }

    // Top section before conical cap
    final capBaseY = baseY - totalH * 0.88;
    path.lineTo(cx - halfW * 0.6, capBaseY);

    // Conical pointed roof (Kulah) to top pinnacle
    path.lineTo(cx, topY);

    // Down the other side (symmetrical right)
    path.lineTo(cx + halfW * 0.6, capBaseY);
    if (hasUpperBalcony) {
      path.lineTo(cx + halfW * 0.65, upperBalconyY - totalH * 0.035);
      path.lineTo(cx + halfW * 1.25, upperBalconyY - totalH * 0.035);
      path.lineTo(cx + halfW * 1.25, upperBalconyY);
      path.lineTo(cx + halfW * 0.75, upperBalconyY);
    }
    path.lineTo(cx + halfW * 0.8, lowerBalconyY - totalH * 0.04);
    path.lineTo(cx + halfW * 1.45, lowerBalconyY - totalH * 0.04);
    path.lineTo(cx + halfW * 1.45, lowerBalconyY);
    path.lineTo(cx + halfW * 0.9, lowerBalconyY);
    path.lineTo(cx + halfW * 1.1, pedY);
    path.lineTo(cx + halfW * 1.25, baseY);
  }

  /// Draws a crescent finial (Hilal) at the tip of a dome or minaret spire.
  static void _drawHilalFinial(
    Canvas canvas,
    double cx,
    double topY, {
    required double size,
    required Paint paint,
  }) {
    // Spire rod
    final spirePath = Path();
    spirePath.moveTo(cx - 1.0, topY);
    spirePath.lineTo(cx - 0.8, topY - size * 0.65);
    spirePath.lineTo(cx + 0.8, topY - size * 0.65);
    spirePath.lineTo(cx + 1.0, topY);
    spirePath.close();
    canvas.drawPath(spirePath, paint);

    // Crescent moon at the rod tip
    final moonCenter = Offset(cx, topY - size * 0.75);
    final moonR = size * 0.45;

    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: moonR));

    final innerPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(moonCenter.dx + moonR * 0.38, moonCenter.dy - moonR * 0.15),
          radius: moonR * 0.82,
        ),
      );

    final crescentPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(crescentPath, paint);
  }

  /// Draws a soft crescent moon in the open sky.
  static void _drawSkyCrescent(
    Canvas canvas, {
    required double cx,
    required double cy,
    required double radius,
    required Color paint,
  }) {
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    final innerPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(cx + radius * 0.42, cy - radius * 0.22),
          radius: radius * 0.84,
        ),
      );

    final moonPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    final p = Paint()
      ..color = paint
      ..style = PaintingStyle.fill;
    canvas.drawPath(moonPath, p);
  }

  /// Draws a four-point twinkling star.
  static void _drawStar(
    Canvas canvas, {
    required double cx,
    required double cy,
    required double radius,
    required Color color,
  }) {
    final path = Path();
    path.moveTo(cx, cy - radius);
    path.quadraticBezierTo(cx, cy, cx + radius, cy);
    path.quadraticBezierTo(cx, cy, cx, cy + radius);
    path.quadraticBezierTo(cx, cy, cx - radius, cy);
    path.quadraticBezierTo(cx, cy, cx, cy - radius);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  /// Draws a row of traditional pointed arches.
  static void _drawArchedWindowRow(
    Canvas canvas, {
    required double cx,
    required double y,
    required double width,
    required double height,
    required int count,
    required double spacing,
    required Paint paint,
  }) {
    final startX = cx - ((count - 1) * spacing) / 2;
    for (int i = 0; i < count; i++) {
      _drawArchedWindow(
        canvas,
        cx: startX + i * spacing,
        y: y,
        width: width,
        height: height,
        paint: paint,
      );
    }
  }

  /// Draws a single authentic Islamic pointed arch window.
  static void _drawArchedWindow(
    Canvas canvas, {
    required double cx,
    required double y,
    required double width,
    required double height,
    required Paint paint,
  }) {
    final halfW = width / 2;
    final archTopY = y - height;
    final springY = y - height * 0.45; // where arch begins curving

    final path = Path();
    path.moveTo(cx - halfW, y);
    path.lineTo(cx - halfW, springY);
    // Pointed arch curves
    path.quadraticBezierTo(cx - halfW * 0.3, springY - (springY - archTopY) * 0.9, cx, archTopY);
    path.quadraticBezierTo(cx + halfW * 0.3, springY - (springY - archTopY) * 0.9, cx + halfW, springY);
    path.lineTo(cx + halfW, y);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MosqueSilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}

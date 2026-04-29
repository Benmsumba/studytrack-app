import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildRadarChartCard(),
              const SizedBox(height: 16),
              _buildHeatmapCard(),
            ],
          ),
        ),
      ),
    );

  Widget _buildHeader() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Analytics',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See Wrapped ',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7C3AED),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                '✦',
                style: TextStyle(color: Color(0xFF7C3AED), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildStatsRow() {
    // Placeholder: Replace with dynamic data from analytics provider
    final stats = [
      {'icon': '🔥', 'label': 'Streak:', 'value': '12 Days'},
      {'icon': '🏆', 'label': 'Mastered:', 'value': '45'},
      {'icon': '📚', 'label': 'Week:', 'value': '18 Sessions'},
      {'icon': '⭐', 'label': 'Avg:', 'value': '8.4/10'},
    ];

    return Row(
      children: stats.map((s) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: s != stats.last ? 8 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D2D44)),
            ),
            child: Column(
              children: [
                Text(s['icon']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  s['label']!,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  s['value']!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )).toList(),
    );
  }

  Widget _buildRadarChartCard() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Radar Chart',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _RadarChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );

  Widget _buildHeatmapCard() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Consistency Heatmap',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'GitHub style',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          _HeatmapGrid(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12 weeks × 7 days',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 10,
                ),
              ),
              Text(
                '1 week',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
}

class _HeatmapGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const weeks = 12;
    const days = 7;
    final random = <List<double>>[
      for (int w = 0; w < weeks; w++)
        [for (int d = 0; d < days; d++) (d + w) % 5 / 4.0],
    ];

    return Row(
      children: List.generate(weeks, (w) => Expanded(
          child: Column(
            children: List.generate(days, (d) {
              final intensity = random[w][d];
              return Container(
                margin: const EdgeInsets.all(1.5),
                height: 10,
                decoration: BoxDecoration(
                  color: intensity < 0.1
                      ? const Color(0xFF2D2D44)
                      : Color.lerp(
                          const Color(0xFF3B1F7C),
                          const Color(0xFF7C3AED),
                          intensity,
                        ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        )),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    const subjects = [
      'Anatomy',
      'Physiology',
      'Biochem',
      'Bionic',
      'Anatomy',
      'Eumtory',
    ];
    final values = [0.8, 0.9, 0.7, 0.85, 0.6, 0.75];

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF2D2D44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i < subjects.length; i++) {
        final angle = (i * 2 * math.pi / subjects.length) - math.pi / 2;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw spoke lines
    for (var i = 0; i < subjects.length; i++) {
      final angle = (i * 2 * math.pi / subjects.length) - math.pi / 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        gridPaint,
      );
    }

    // Draw data polygon
    final dataPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final dataStrokePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dataPath = Path();
    for (var i = 0; i < subjects.length; i++) {
      final angle = (i * 2 * math.pi / subjects.length) - math.pi / 2;
      final r = radius * values[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // Draw dots and labels
    final dotPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < subjects.length; i++) {
      final angle = (i * 2 * math.pi / subjects.length) - math.pi / 2;
      final r = radius * values[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // Labels
      final labelR = radius + 18;
      final lx = center.dx + labelR * math.cos(angle);
      final ly = center.dy + labelR * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: subjects[i],
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

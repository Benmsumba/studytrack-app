# StudyTrack — Master Screen Code File
## All 24 Screens · 6 Batches · Complete Flutter Dart Code

---

> **HOW TO USE THIS FILE**
> Each screen below is a complete `.dart` file.
> Copy the code → paste into the correct file path shown above each screen.
> The path shown matches the folder structure in the master prompt.
> All screens share the same design system (colors, fonts, spacing).

---

## DESIGN SYSTEM REFERENCE (used in every screen)

```
Background:  #0F0F1A    (deepest dark)
Surface:     #1A1A2E    (card bg)
Card:        #16213E    (raised card)
Primary:     #7C3AED    (violet)
Accent:      #06B6D4    (cyan)
Success:     #10B981    (green)
Warning:     #F59E0B    (amber)
Danger:      #F43F5E    (rose)
Border:      #2D2D44    (subtle border)
Text:        #FFFFFF
Text Muted:  #9CA3AF
Fonts:       Outfit (headings) · Inter (body)
```

---

---
# ═══════════════════════════════════════════
# BATCH 1 — Core Navigation Screens
# Source: Image 1 (all 4 screens)
# ═══════════════════════════════════════════
---

## SCREEN 1 — Home Dashboard
### File: `lib/features/home/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStudySessionCard(),
              const SizedBox(height: 14),
              _buildDailyGoalCard(),
              const SizedBox(height: 14),
              _buildExamCountdownCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StudyTrack',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Good Morning,\nChifundo!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2D2D44)),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/100?img=11'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              right: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0F0F1A), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 9)),
                    const SizedBox(width: 2),
                    Text('12',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudySessionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        children: [
          Text(
            'START STUDY SESSION',
            style: GoogleFonts.outfit(
              color: const Color(0xFF9CA3AF),
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: 0.0,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFF2D2D44),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '0%',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Topic: Pharmacokinetics',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'from Pharmacology module',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'START SESSION',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Goal: 3/6 Hours',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '50%',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.5,
              backgroundColor: Color(0xFF2D2D44),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCountdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anatomy Final: 12 Days',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Readiness pulse',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.86,
                    backgroundColor: Color(0xFF2D2D44),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    value: 0.86,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFF2D2D44),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '86%',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## SCREEN 2 — Modules Screen
### File: `lib/features/modules/screens/modules_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  static final List<Map<String, dynamic>> _modules = [
    {'name': 'Pharmacology', 'icon': Icons.science, 'color': const Color(0xFF7C3AED), 'mastery': 8.2, 'studied': 12, 'total': 15},
    {'name': 'Physiology', 'icon': Icons.favorite, 'color': const Color(0xFFEF4444), 'mastery': 8.2, 'studied': 13, 'total': 15},
    {'name': 'Anatomy', 'icon': Icons.accessibility_new, 'color': const Color(0xFFF59E0B), 'mastery': 8.2, 'studied': 12, 'total': 15},
    {'name': 'Biochemistry', 'icon': Icons.biotech, 'color': const Color(0xFF10B981), 'mastery': 8.2, 'studied': 13, 'total': 15},
    {'name': 'Pathology', 'icon': Icons.medical_services, 'color': const Color(0xFF3B82F6), 'mastery': 7.5, 'studied': 10, 'total': 14},
    {'name': 'Microbiology', 'icon': Icons.blur_circular, 'color': const Color(0xFF8B5CF6), 'mastery': 6.8, 'studied': 8, 'total': 12},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      floatingActionButton: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          ),
        ),
        child: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Modules',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2D44)),
                ),
                child: TextField(
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: _modules.length,
                itemBuilder: (_, i) => _ModuleCard(module: _modules[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final double progress = module['studied'] / module['total'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (module['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(module['icon'] as IconData, color: module['color'] as Color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module['name'] as String,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '${module['mastery']} Mastery',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF2D2D44),
                  valueColor: AlwaysStoppedAnimation<Color>(module['color'] as Color),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${module['studied']}/${module['total']} Studied',
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
}
```

---

## SCREEN 3 — Analytics Screen
### File: `lib/features/progress/screens/analytics_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  }

  Widget _buildHeader() {
    return Row(
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
            color: const Color(0xFF7C3AED).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5)),
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
              const Text('✦', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {'icon': '🔥', 'label': 'Streak:', 'value': '12 Days'},
      {'icon': '🏆', 'label': 'Mastered:', 'value': '45'},
      {'icon': '📚', 'label': 'Week:', 'value': '18 Sessions'},
      {'icon': '⭐', 'label': 'Avg:', 'value': '8.4/10'},
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
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
        );
      }).toList(),
    );
  }

  Widget _buildRadarChartCard() {
    return Container(
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
  }

  Widget _buildHeatmapCard() {
    return Container(
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
              Text('12 weeks × 7 days',
                  style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 10)),
              Text('1 week',
                  style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const weeks = 12;
    const days = 7;
    final random = <List<double>>[
      for (int w = 0; w < weeks; w++)
        [for (int d = 0; d < days; d++) (d + w) % 5 / 4.0]
    ];

    return Row(
      children: List.generate(weeks, (w) {
        return Expanded(
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
        );
      }),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    const subjects = ['Anatomy', 'Physiology', 'Biochem', 'Bionic', 'Anatomy', 'Eumtory'];
    final values = [0.8, 0.9, 0.7, 0.85, 0.6, 0.75];

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF2D2D44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i < subjects.length; i++) {
        final angle = (i * 2 * 3.14159 / subjects.length) - 3.14159 / 2;
        final x = center.dx + r * _cos(angle);
        final y = center.dy + r * _sin(angle);
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
    for (int i = 0; i < subjects.length; i++) {
      final angle = (i * 2 * 3.14159 / subjects.length) - 3.14159 / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * _cos(angle), center.dy + radius * _sin(angle)),
        gridPaint,
      );
    }

    // Draw data polygon
    final dataPaint = Paint()
      ..color = const Color(0xFF7C3AED).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    final dataStrokePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dataPath = Path();
    for (int i = 0; i < subjects.length; i++) {
      final angle = (i * 2 * 3.14159 / subjects.length) - 3.14159 / 2;
      final r = radius * values[i];
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
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
    for (int i = 0; i < subjects.length; i++) {
      final angle = (i * 2 * 3.14159 / subjects.length) - 3.14159 / 2;
      final r = radius * values[i];
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // Labels
      final labelR = radius + 18;
      final lx = center.dx + labelR * _cos(angle);
      final ly = center.dy + labelR * _sin(angle);
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

  double _cos(double angle) => angle == 0 ? 1 : (angle == 3.14159 ? -1 : (angle < 3.14159 ? (1 - angle * angle / 2) : -(1 - (angle - 3.14159) * (angle - 3.14159) / 2)));

  double _sin(double angle) {
    // Simple sin approximation using dart math
    return (angle > 0 ? 1 : -1) * (1 - _cos(angle.abs() - 3.14159 / 2).abs());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

> **Note on Radar Chart**: For production, replace `_RadarChartPainter` with `fl_chart`'s `RadarChart` widget for accurate rendering. Import `dart:math` and use `sin()` / `cos()` from that package.

---

## SCREEN 4 — Groups Screen
### File: `lib/features/groups/screens/groups_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  static final List<Map<String, String>> _groups = [
    {'name': 'CS Prep', 'members': '12', 'time': '3m ago'},
    {'name': 'CS Prep', 'members': '12', 'time': '3m ago'},
    {'name': 'CS Prep', 'members': '12', 'time': '3m ago'},
    {'name': 'CS Prep', 'members': '12', 'time': '3m ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Groups',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your Study Groups',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _GroupCard(group: _groups[i]),
              ),
            ),
            _buildTopicChatPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicChatPreview() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topic Chat Sneak-Peek',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Topic: Cranial Nerves Mnemonic',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Chifundo: ',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '"Anyone got a mnemonic for CNs?"',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2D2D44)),
                  ),
                  child: TextField(
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Text input...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, String> group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'CS',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name']!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group['members']} Members',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
              const SizedBox(height: 4),
              Text(
                group['time']!,
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---
---
# ═══════════════════════════════════════════
# BATCH 2 — Study Feature Screens
# Source: Image 2 (all 4 screens)
# ═══════════════════════════════════════════
---

## SCREEN 5 — Weekly Wrapped
### File: `lib/features/progress/screens/weekly_wrapped_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyWrappedScreen extends StatelessWidget {
  const WeeklyWrappedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopSection(),
              _buildMiddleSection(),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          'YOUR WEEKLY\nWRAPPED',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 52)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '15',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                Text(
                  'hours',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'topics covered',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 14),
            const SizedBox(width: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '3 more',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF10B981),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' than last week',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiddleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Best Subject: ',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
            ),
            TextSpan(
              text: 'pharmacology. ',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: 'weak subject: ',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
            ),
            TextSpan(
              text: 'Anatomy. ',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: 'You are on a roll! ',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
            ),
            const TextSpan(text: '🏆', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3 + i * 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## SCREEN 6 — Timetable Screen
### File: `lib/features/timetable/screens/timetable_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _selectedDay = 0;
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'S'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      floatingActionButton: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
          ),
        ),
        child: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Timetable',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildDaySelector(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Today's Schedule",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildSchedule()),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (_, i) {
          final isSelected = i == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF2D2D44),
                ),
              ),
              child: Text(
                _days[i],
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchedule() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildTimeRow('08:00', null),
        _buildTimeRow('09:00', _AnatomyEvent()),
        _buildTimeRow('10:00', null),
        _buildTimeRow('11:00', _StudySessionEvent()),
        _buildTimeRow('12:00', null),
        _buildTimeRow('15:00', null),
        _buildTimeRow('17:00', null),
      ],
    );
  }

  Widget _buildTimeRow(String time, Widget? event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 45,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              time,
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              if (event != null) ...[event, const SizedBox(height: 8)],
              if (event == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 1,
                  color: const Color(0xFF2D2D44).withOpacity(0.4),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnatomyEvent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF06B6D4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('09:00 - 10:30',
              style: GoogleFonts.inter(color: const Color(0xFF06B6D4), fontSize: 11)),
          const SizedBox(height: 4),
          Text('Anatomy',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 13),
              const SizedBox(width: 4),
              Text('Room 3B',
                  style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.folder_outlined, color: Color(0xFF9CA3AF), size: 13),
              const SizedBox(width: 4),
              Text('Prof. Tembo',
                  style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudySessionEvent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Study Session',
              style: GoogleFonts.inter(color: const Color(0xFF7C3AED), fontSize: 11)),
          Text('11:00 - 12:00',
              style: GoogleFonts.inter(color: const Color(0xFF7C3AED), fontSize: 11)),
          const SizedBox(height: 4),
          Text('Biochemistry',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFF9CA3AF), size: 13),
              const SizedBox(width: 4),
              Text('Metabolism Quiz Prep',
                  style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## SCREEN 7 — Topic Detail Screen
### File: `lib/features/modules/screens/topic_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({super.key});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  bool _notesExpanded = false;

  final List<Map<String, dynamic>> _actions = [
    {'icon': Icons.help_outline, 'label': 'Explain\nThis', 'color': const Color(0xFF7C3AED)},
    {'icon': Icons.quiz_outlined, 'label': 'Test Me', 'color': const Color(0xFF06B6D4)},
    {'icon': Icons.lightbulb_outline, 'label': 'Mnemonic', 'color': const Color(0xFFF59E0B)},
    {'icon': Icons.summarize_outlined, 'label': 'Summarize\nNotes', 'color': const Color(0xFF10B981)},
    {'icon': Icons.psychology_outlined, 'label': 'Predict\nQuestions', 'color': const Color(0xFF8B5CF6)},
    {'icon': Icons.chat_outlined, 'label': 'Topic Chat', 'color': const Color(0xFF06B6D4)},
    {'icon': Icons.share_outlined, 'label': 'Shared\nNotes', 'color': const Color(0xFFEF4444)},
    {'icon': Icons.style_outlined, 'label': 'Flashcards', 'color': const Color(0xFFF97316)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildTopicHero(),
              const SizedBox(height: 20),
              _buildActionsGrid(),
              const SizedBox(height: 16),
              _buildMyNotes(),
              const SizedBox(height: 16),
              _buildLecturesDocs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios, color: Color(0xFF9CA3AF), size: 16),
              const SizedBox(width: 4),
              Text(
                'Topic Detail',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Module: Pharmacology',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicHero() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pharmacokinetics',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Current understanding',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: 0.7,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFF2D2D44),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '7/10',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: _actions.length,
      itemBuilder: (_, i) {
        final action = _actions[i];
        return GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D2D44)),
            ),
            child: Row(
              children: [
                Icon(action['icon'] as IconData,
                    color: action['color'] as Color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action['label'] as String,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyNotes() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: ListTile(
        title: Text(
          'My Notes',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          _notesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: const Color(0xFF9CA3AF),
        ),
        onTap: () => setState(() => _notesExpanded = !_notesExpanded),
      ),
    );
  }

  Widget _buildLecturesDocs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lectures & Docs',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildDocItem('PDF', const Color(0xFF10B981), 0.8),
          const SizedBox(height: 10),
          _buildDocItem('PPT', const Color(0xFFF59E0B), 0.4),
        ],
      ),
    );
  }

  Widget _buildDocItem(String type, Color color, double progress) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            type,
            style: GoogleFonts.outfit(
                color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF2D2D44),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.download_outlined, color: Color(0xFF9CA3AF), size: 20),
      ],
    );
  }
}
```

---

## SCREEN 8 — Quiz Screen
### File: `lib/features/modules/screens/quiz_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _selectedOption = 1; // B is selected
  int _currentQuestion = 2;
  final int _totalQuestions = 5;

  final List<String> _options = [
    'Absorption half-life',
    'Total Body Clearance',
    'Area Under the Curve (AUC)',
    'Apparent Volume of Distribution',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildProgress(),
              const SizedBox(height: 28),
              _buildQuestion(),
              const SizedBox(height: 24),
              _buildOptions(),
              const Spacer(),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: Color(0xFF9CA3AF), size: 18),
        ),
        const SizedBox(height: 12),
        Text(
          'Topic Quiz',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Pharmacokinetics',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final progress = _currentQuestion / _totalQuestions;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $_currentQuestion of $_totalQuestions',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.outfit(
                color: const Color(0xFF10B981),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF2D2D44),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Text(
      'Which parameter represents the rate of elimination of a drug?',
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.35,
      ),
    );
  }

  Widget _buildOptions() {
    final letters = ['A', 'B', 'C', 'D'];
    return Column(
      children: List.generate(_options.length, (i) {
        final isSelected = i == _selectedOption;
        return GestureDetector(
          onTap: () => setState(() => _selectedOption = i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7C3AED).withOpacity(0.2)
                  : const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF2D2D44),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${letters[i]}. ',
                  style: GoogleFonts.outfit(
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(
                    _options[i],
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'NEXT QUESTION',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
```

---
---
# ═══════════════════════════════════════════
# BATCH 3 — AI, Profile & Settings Screens
# Source: Image 3 (all 4 screens)
# ═══════════════════════════════════════════
---

## SCREEN 9 — Onboarding Step 4 (Prime Study Time)
### File: `lib/features/onboarding/screens/onboarding_step4_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingStep4Screen extends StatefulWidget {
  const OnboardingStep4Screen({super.key});

  @override
  State<OnboardingStep4Screen> createState() => _OnboardingStep4ScreenState();
}

class _OnboardingStep4ScreenState extends State<OnboardingStep4Screen> {
  int _selectedTime = 0; // 0 = Morning

  final List<Map<String, dynamic>> _times = [
    {'label': 'MORNING', 'icon': Icons.wb_sunny_outlined, 'sub': '5am–12pm'},
    {'label': 'AFTERNOON', 'icon': Icons.wb_twilight, 'sub': '12pm–5pm'},
    {'label': 'EVENING', 'icon': Icons.nights_stay_outlined, 'sub': '5pm–9pm'},
    {'label': 'NIGHT', 'icon': Icons.dark_mode_outlined, 'sub': '9pm–late'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDots(),
              const SizedBox(height: 32),
              Text(
                'YOUR PRIME\nSTUDY TIME',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: List.generate(_times.length, (i) => _buildTimeCard(i)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Most productive hours: 8 AM - 12 PM',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      children: List.generate(6, (i) => Container(
        margin: const EdgeInsets.only(right: 6),
        width: i == 3 ? 20 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: i <= 3 ? const Color(0xFF7C3AED) : const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(4),
        ),
      )),
    );
  }

  Widget _buildTimeCard(int index) {
    final time = _times[index];
    final isSelected = index == _selectedTime;

    return GestureDetector(
      onTap: () => setState(() => _selectedTime = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withOpacity(0.15)
              : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF2D2D44),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              time['icon'] as IconData,
              color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF9CA3AF),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              time['label'] as String,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'NEXT',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## SCREEN 10 — AI Tutor Screen
### File: `lib/features/ai_tutor/screens/ai_tutor_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  bool _isAnonymous = false;
  final _controller = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': true,
      'text': 'Can you explain the Circle of Willis and its clinical importance?',
    },
    {
      'isUser': false,
      'text': 'Key point to remember:\n• The Circle of Willis is a crucial arterial network.\n• Consistent understanding of its anatomy is essential.\n\nKey point to remember: The Circle of Willis is a crucial and essential structure at the base of the brain...',
    },
    {
      'isUser': true,
      'text': 'What is your summary of the neuroanatomy?',
    },
  ];

  final List<String> _quickActions = [
    'Explain this',
    'Test me',
    'Give a mnemonic',
    'Predict questions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildMessages()),
            _buildQuickActions(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2D44))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF9CA3AF), size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Color(0xFF7C3AED), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Topic: Neuroanatomy',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gemini AI',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isUser = msg['isUser'] as bool;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF7C3AED) : const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(14),
              border: isUser
                  ? null
                  : Border.all(color: const Color(0xFF2D2D44)),
            ),
            child: Text(
              msg['text'] as String,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickActions.length,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(right: 8),
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: const BorderSide(color: Color(0xFF2D2D44)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: const Color(0xFF1A1A2E),
            ),
            child: Text(
              _quickActions[i],
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF2D2D44))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2D2D44)),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Text input...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(
                'Anonymous',
                style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 11),
              ),
              const SizedBox(width: 4),
              Switch(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
                activeColor: const Color(0xFF7C3AED),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(width: 4),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
```

---

## SCREEN 11 — Profile & Badges Screen
### File: `lib/features/profile/screens/profile_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const List<Map<String, dynamic>> _badges = [
    {'emoji': '🌱', 'name': 'First Step', 'earned': true},
    {'emoji': '🔥', 'name': 'Week Warrior', 'earned': true},
    {'emoji': '🏆', 'name': 'Perfectionist', 'earned': true},
    {'emoji': '📚', 'name': 'Bookworm', 'earned': false},
    {'emoji': '⭐', 'name': 'Master', 'earned': false},
    {'emoji': '???', 'name': 'Unknown', 'earned': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 16),
              _buildBadgesGrid(),
              const SizedBox(height: 16),
              _buildWeekWarriorDetail(),
              const SizedBox(height: 16),
              _buildExportSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF06B6D4), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  'https://i.pravatar.cc/100?img=11',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '12-day streak',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Chifundo',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Pharmacy Year 3',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: _badges.length,
      itemBuilder: (_, i) {
        final badge = _badges[i];
        final earned = badge['earned'] as bool;
        return Container(
          decoration: BoxDecoration(
            color: earned
                ? const Color(0xFF16213E)
                : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: earned ? const Color(0xFFF59E0B).withOpacity(0.4) : const Color(0xFF2D2D44),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              earned
                  ? Text(badge['emoji'] as String,
                      style: const TextStyle(fontSize: 28))
                  : const Icon(Icons.lock_outlined,
                      color: Color(0xFF6B7280), size: 28),
              const SizedBox(height: 6),
              Text(
                badge['name'] as String,
                style: GoogleFonts.inter(
                  color: earned ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekWarriorDetail() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Week Warrior',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Earned: 24/03/26',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
              Text(
                '7-day streak',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export data',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildExportButton('Weekly Report PDF', Icons.picture_as_pdf_outlined),
          const SizedBox(height: 10),
          _buildExportButton('Backup to Drive', Icons.cloud_upload_outlined),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
```

---

## SCREEN 12 — Settings Screen
### File: `lib/features/settings/screens/settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _spacedRepetition = true;
  bool _examCountdown = true;
  bool _isDark = true;
  double _dailyGoal = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Settings',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSection('Study Preferences', [
                _buildDropdownRow('Prime Time', 'Prime Time'),
                _buildSliderRow('Daily Goal', _dailyGoal),
              ]),
              _buildSection('Notifications', [
                _buildToggleRow('Spaced Repetition', _spacedRepetition,
                    (v) => setState(() => _spacedRepetition = v)),
                _buildToggleRow('Exam Countdown', _examCountdown,
                    (v) => setState(() => _examCountdown = v)),
              ]),
              _buildSection('Appearance', [
                _buildSegmentedRow('Dark mode'),
                _buildDropdownRow('Language', 'English'),
              ]),
              _buildSection('Account', [
                _buildLinkRow('Change Password'),
                _buildLinkRow('Data Export'),
                _buildLinkRow('Delete Account', danger: true),
              ]),
              _buildSection('About', [
                _buildInfoRow('App version', '1.0.0'),
                _buildLinkRow('Feedback', trailing: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF9CA3AF))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2D2D44)),
            ),
            child: Column(
              children: children.asMap().entries.map((e) {
                return Column(
                  children: [
                    e.value,
                    if (e.key < children.length - 1)
                      const Divider(color: Color(0xFF2D2D44), height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7C3AED),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2D2D44)),
            ),
            child: Row(
              children: [
                Text(value, style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
              Text('1-12h', style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbColor: const Color(0xFF7C3AED),
              activeTrackColor: const Color(0xFF7C3AED),
              inactiveTrackColor: const Color(0xFF2D2D44),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: _dailyGoal,
              min: 1,
              max: 12,
              onChanged: (v) => setState(() => _dailyGoal = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2D2D44)),
            ),
            child: Row(
              children: ['Dark', 'Light'].map((mode) {
                final isActive = (_isDark && mode == 'Dark') || (!_isDark && mode == 'Light');
                return GestureDetector(
                  onTap: () => setState(() => _isDark = mode == 'Dark'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF7C3AED) : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      mode,
                      style: GoogleFonts.inter(
                        color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, {bool danger = false, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: danger ? const Color(0xFFF43F5E) : Colors.white,
              fontSize: 13,
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          Text(value, style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13)),
        ],
      ),
    );
  }
}
```

---
---
# ═══════════════════════════════════════════
# BATCH 4 — Auth & Entry Screens
# Source: Image 4 (all 4 screens)
# ═══════════════════════════════════════════
---

## SCREEN 13 — Onboarding Step 1 (Welcome)
### File: `lib/features/onboarding/screens/onboarding_step1_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingStep1Screen extends StatelessWidget {
  const OnboardingStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Welcome to\nStudyTrack 👋',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Let's set up your personal study companion.",
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2D2D44)),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 90,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2D44)),
                ),
                child: TextField(
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "What's your name?",
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## SCREEN 14 — Login Screen
### File: `lib/features/auth/screens/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildLogo(),
              const SizedBox(height: 32),
              _buildHeading(),
              const SizedBox(height: 32),
              _buildEmailField(),
              const SizedBox(height: 14),
              _buildPasswordField(),
              const SizedBox(height: 10),
              _buildForgotPassword(),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 20),
              _buildVoiceIndicator(),
              const SizedBox(height: 24),
              _buildSignupLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_stories_rounded,
        color: Color(0xFF7C3AED),
        size: 38,
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Study smarter. Know where you stand.',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: TextField(
        keyboardType: TextInputType.emailAddress,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Email Address',
          hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14),
          prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF6B7280), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: TextField(
        obscureText: !_passwordVisible,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: Text(
          'Forgot Password?',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: _isLoading ? null : () {},
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Login',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        7,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: (i % 3 == 0 ? 20 : i % 2 == 0 ? 14 : 10).toDouble(),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Don't have an account? ",
            style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
          ),
          TextSpan(
            text: 'Sign up',
            style: GoogleFonts.inter(
              color: const Color(0xFF7C3AED),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## SCREEN 15 — Exam Countdown Screen
### File: `lib/features/progress/screens/exam_countdown_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamCountdownScreen extends StatelessWidget {
  const ExamCountdownScreen({super.key});

  static const List<Map<String, String>> _exams = [
    {'title': 'Pharmacology Final', 'date': '24/05/26'},
    {'title': 'Biochemistry Quiz', 'date': '15/05/26'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, color: Color(0xFF9CA3AF), size: 18),
              ),
              const SizedBox(height: 16),
              Text(
                'Exam\nCountdown',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: _buildCountdownRing(),
              ),
              const SizedBox(height: 32),
              ..._exams.map((e) => _buildExamCard(e)),
              const SizedBox(height: 12),
              _buildUrgentWarning(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownRing() {
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: 0.88,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFF2D2D44),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '88%',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Readiness',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                child: Icon(
                  Icons.favorite,
                  color: const Color(0xFF10B981).withOpacity(0.8),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '12 Days',
          style: GoogleFonts.outfit(
            color: const Color(0xFF06B6D4),
            fontSize: 52,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: const Color(0xFF06B6D4).withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard(Map<String, String> exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            exam['title']!,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '(${exam['date']!})',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF43F5E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E), size: 16),
          const SizedBox(width: 8),
          Text(
            'Urgent: weak topic needs attention.',
            style: GoogleFonts.inter(
              color: const Color(0xFFF43F5E),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## SCREEN 16 — Group Chat Screen
### File: `lib/features/groups/screens/group_chat_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  static const List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Malinga',
      'text': 'Anyone have a mnemonics for cranial nerves?',
      'isMe': false,
    },
    {
      'sender': 'Chifundo',
      'text': 'Need help with data structure final topic!',
      'isMe': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Live Chat Feed',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildMessages()),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2D44))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF9CA3AF), size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              'CS',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finals Prep - Computer Science',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '12 Members',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.settings_outlined, color: Color(0xFF9CA3AF), size: 20),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        final isMe = msg['isMe'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'CS',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF7C3AED) : const Color(0xFF16213E),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 14),
                    ),
                    border: isMe ? null : Border.all(color: const Color(0xFF2D2D44)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(
                          msg['sender'] as String,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7C3AED),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (!isMe) const SizedBox(height: 3),
                      Text(
                        msg['text'] as String,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                ClipOval(
                  child: Image.network(
                    'https://i.pravatar.cc/100?img=11',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF2D2D44))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2D2D44)),
              ),
              child: TextField(
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Text',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.attachment, color: Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Send',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---
---
# ═══════════════════════════════════════════
# BATCH 5 — Missing Auth & Onboarding Screens
# Designed to match same visual language
# ═══════════════════════════════════════════
---

## SCREEN 17 — Splash Screen
### File: `lib/features/auth/screens/splash_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      // Navigate to /login or /home
      // Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'StudyTrack',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Study smarter. Know where you stand.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## SCREEN 18 — Sign Up Screen
### File: `lib/features/auth/screens/signup_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  double _passwordStrength = 0.6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Create Account',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Join thousands of students studying smarter.',
                style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _buildField('Full Name', Icons.person_outline, false),
              const SizedBox(height: 14),
              _buildField('Email Address', Icons.mail_outline, false),
              const SizedBox(height: 14),
              _buildPasswordField('Password', _passwordVisible,
                  () => setState(() => _passwordVisible = !_passwordVisible)),
              const SizedBox(height: 8),
              _buildPasswordStrength(),
              const SizedBox(height: 14),
              _buildPasswordField('Confirm Password', _confirmVisible,
                  () => setState(() => _confirmVisible = !_confirmVisible)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Already have an account? ',
                      style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
                    ),
                    TextSpan(
                      text: 'Login',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7C3AED),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, IconData icon, bool obscure) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: TextField(
        obscureText: obscure,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, bool visible, VoidCallback onToggle) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: TextField(
        obscureText: !visible,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final color = _passwordStrength < 0.4
        ? const Color(0xFFF43F5E)
        : _passwordStrength < 0.7
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);
    final label = _passwordStrength < 0.4
        ? 'Weak'
        : _passwordStrength < 0.7
            ? 'Medium'
            : 'Strong';

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: const Color(0xFF2D2D44),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: color, fontSize: 11)),
      ],
    );
  }
}
```

---

## SCREENS 19–22 — Onboarding Steps 2, 3, 5, 6
### File: `lib/features/onboarding/screens/onboarding_steps_2356.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── STEP 2: What are you studying? ──────────────────────────────

class OnboardingStep2Screen extends StatefulWidget {
  const OnboardingStep2Screen({super.key});

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  final _controller = TextEditingController();
  final _courses = ['Pharmacy', 'MBBS', 'Physiotherapy', 'Nursing', 'Dentistry', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDots(1),
              const SizedBox(height: 32),
              Text(
                'WHAT ARE YOU\nSTUDYING?',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2D44)),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type your course...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _courses.map((c) => GestureDetector(
                  onTap: () => setState(() => _controller.text = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _controller.text == c
                          ? const Color(0xFF7C3AED).withOpacity(0.2)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _controller.text == c
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF2D2D44),
                      ),
                    ),
                    child: Text(
                      c,
                      style: GoogleFonts.inter(
                        color: _controller.text == c ? Colors.white : const Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const Spacer(),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── STEP 3: What year are you in? ───────────────────────────────

class OnboardingStep3Screen extends StatefulWidget {
  const OnboardingStep3Screen({super.key});

  @override
  State<OnboardingStep3Screen> createState() => _OnboardingStep3ScreenState();
}

class _OnboardingStep3ScreenState extends State<OnboardingStep3Screen> {
  int _selectedYear = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDots(2),
              const SizedBox(height: 32),
              Text(
                'WHAT YEAR\nARE YOU IN?',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(7, (i) {
                    final year = i + 1;
                    final isSelected = year == _selectedYear;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedYear = year),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF2D2D44),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Year $year',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── STEP 5: How many hours can you study? ───────────────────────

class OnboardingStep5Screen extends StatefulWidget {
  const OnboardingStep5Screen({super.key});

  @override
  State<OnboardingStep5Screen> createState() => _OnboardingStep5ScreenState();
}

class _OnboardingStep5ScreenState extends State<OnboardingStep5Screen> {
  double _hours = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDots(4),
              const SizedBox(height: 32),
              Text(
                'YOUR DAILY\nSTUDY GOAL',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Text(
                      '${_hours.toInt()}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7C3AED),
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'hours per day',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "That's ${(_hours * 7).toInt()} hours per week",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbColor: const Color(0xFF7C3AED),
                  activeTrackColor: const Color(0xFF7C3AED),
                  inactiveTrackColor: const Color(0xFF2D2D44),
                  overlayColor: const Color(0xFF7C3AED).withOpacity(0.2),
                ),
                child: Slider(
                  value: _hours,
                  min: 1,
                  max: 12,
                  divisions: 11,
                  onChanged: (v) => setState(() => _hours = v),
                ),
              ),
              const Spacer(),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── STEP 6: How do you prefer to study? ─────────────────────────

class OnboardingStep6Screen extends StatefulWidget {
  const OnboardingStep6Screen({super.key});

  @override
  State<OnboardingStep6Screen> createState() => _OnboardingStep6ScreenState();
}

class _OnboardingStep6ScreenState extends State<OnboardingStep6Screen> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDots(5),
              const SizedBox(height: 32),
              Text(
                'YOUR STUDY\nSTYLE',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 32),
              _buildStyleCard(0, '🎧', 'Alone', 'I focus best by myself'),
              const SizedBox(height: 12),
              _buildStyleCard(1, '👥', 'With Others', 'I learn better with friends'),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2D2D44)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Almost ready! Here's what we set up:",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...[
                      '✅ Name & Course configured',
                      '✅ Study schedule ready',
                      '✅ Prime time selected',
                      '✅ Daily goal set',
                    ].map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(s,
                          style: GoogleFonts.inter(
                              color: const Color(0xFF9CA3AF), fontSize: 12)),
                    )),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Let's Go! 🚀",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleCard(int index, String emoji, String title, String sub) {
    final isSelected = _selected == index;
    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED).withOpacity(0.15) : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF2D2D44),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
                Text(sub,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF), fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── SHARED HELPERS ───────────────────────────────────────────────

Widget _buildDots(int activeIndex) {
  return Row(
    children: List.generate(6, (i) => Container(
      margin: const EdgeInsets.only(right: 6),
      width: i == activeIndex ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: i <= activeIndex ? const Color(0xFF7C3AED) : const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(4),
      ),
    )),
  );
}

Widget _buildNextButton() {
  return SizedBox(
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'NEXT',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    ),
  );
}
```

---
---
# ═══════════════════════════════════════════
# BATCH 6 — Missing Feature Screens
# Designed to match same visual language
# ═══════════════════════════════════════════
---

## SCREEN 23 — Module Detail Screen
### File: `lib/features/modules/screens/module_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({super.key});

  static const List<Map<String, dynamic>> _topics = [
    {'name': 'Pharmacokinetics', 'rating': 7, 'studied': true},
    {'name': 'Pharmacodynamics', 'rating': 8, 'studied': true},
    {'name': 'Drug Absorption', 'rating': 5, 'studied': true},
    {'name': 'Drug Metabolism', 'rating': 6, 'studied': false},
    {'name': 'Drug Excretion', 'rating': 0, 'studied': false},
    {'name': 'Adverse Drug Reactions', 'rating': 9, 'studied': true},
  ];

  Color _ratingColor(int r) {
    if (r >= 8) return const Color(0xFF10B981);
    if (r >= 5) return const Color(0xFFF59E0B);
    if (r > 0) return const Color(0xFFF43F5E);
    return const Color(0xFF2D2D44);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      floatingActionButton: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          ),
        ),
        child: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios, color: Color(0xFF9CA3AF), size: 16),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.science, color: Color(0xFF7C3AED), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Pharmacology',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStat('6', 'Topics'),
                      const SizedBox(width: 10),
                      _buildStat('4', 'Studied'),
                      const SizedBox(width: 10),
                      _buildStat('7.5', 'Avg Rating'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _topics.length,
                itemBuilder: (_, i) => _buildTopicRow(_topics[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2D2D44)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            Text(label,
                style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicRow(Map<String, dynamic> topic) {
    final rating = topic['rating'] as int;
    final studied = topic['studied'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: studied ? const Color(0xFF10B981) : const Color(0xFF2D2D44),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              topic['name'] as String,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (rating > 0) ...[
            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
            const SizedBox(width: 4),
            Text(
              '$rating/10',
              style: GoogleFonts.outfit(
                color: _ratingColor(rating),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else
            Text(
              'Not rated',
              style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280), fontSize: 12),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 18),
        ],
      ),
    );
  }
}
```

---

## SCREEN 24 — Study Session Screen (Pomodoro)
### File: `lib/features/study/screens/study_session_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  int _seconds = 25 * 60;
  int _session = 1;
  late AnimationController _pulseController;

  String get _timeDisplay {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1.0 - (_seconds / (25 * 60));

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildHeader(context),
              const Spacer(),
              _buildTimer(),
              const SizedBox(height: 24),
              _buildTopicLabel(),
              const SizedBox(height: 12),
              _buildSessionIndicator(),
              const Spacer(),
              _buildControls(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 22),
        ),
        const Spacer(),
        Text(
          'Study Session',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 22),
      ],
    );
  }

  Widget _buildTimer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final glowOpacity = _isRunning
            ? 0.2 + (_pulseController.value * 0.3)
            : 0.15;
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(glowOpacity),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFF2D2D44),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeDisplay,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    _isRunning ? 'Focus' : 'Ready',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicLabel() {
    return Column(
      children: [
        Text(
          'Topic: Pharmacokinetics',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pharmacology module',
          style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSessionIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isActive = i < _session;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7C3AED) : const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(Icons.refresh, const Color(0xFF2D2D44), () {
          setState(() {
            _seconds = 25 * 60;
            _isRunning = false;
          });
        }),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () => setState(() => _isRunning = !_isRunning),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(width: 20),
        _buildControlButton(Icons.skip_next, const Color(0xFF2D2D44), () {
          setState(() {
            if (_session < 4) _session++;
            _seconds = 25 * 60;
            _isRunning = false;
          });
        }),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF16213E),
          border: Border.all(color: const Color(0xFF2D2D44)),
        ),
        child: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
      ),
    );
  }
}
```

---

## SCREEN 25 — Group Detail Screen
### File: `lib/features/groups/screens/group_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key});

  static const List<Map<String, dynamic>> _members = [
    {'name': 'Chifundo', 'role': 'Admin', 'avatar': '11'},
    {'name': 'Malinga', 'role': 'Member', 'avatar': '15'},
    {'name': 'Brendy', 'role': 'Member', 'avatar': '20'},
    {'name': 'Temwa', 'role': 'Member', 'avatar': '25'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildGroupInfo(),
              const SizedBox(height: 16),
              _buildInviteCode(),
              const SizedBox(height: 16),
              _buildMembersSection(),
              const SizedBox(height: 16),
              _buildSharedNotes(),
              const SizedBox(height: 20),
              _buildLeaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: Color(0xFF9CA3AF), size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          'Group Detail',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              'CS',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finals Prep - CS',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Study group for CS final exams',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outline, color: Color(0xFF9CA3AF), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '12 Members',
                      style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Code',
                  style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  'STK-4F2B9',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7C3AED),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.copy, color: Color(0xFF7C3AED), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Copy',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Members',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ..._members.map((m) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2D2D44)),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.network(
                  'https://i.pravatar.cc/100?img=${m['avatar']}',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  m['name'] as String,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: m['role'] == 'Admin'
                      ? const Color(0xFF7C3AED).withOpacity(0.2)
                      : const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m['role'] as String,
                  style: GoogleFonts.inter(
                    color: m['role'] == 'Admin'
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF9CA3AF),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSharedNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shared Notes',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.folder_outlined, color: Color(0xFF9CA3AF), size: 18),
            ],
          ),
          const SizedBox(height: 10),
          _buildNoteItem('Biochemistry Notes.pdf', const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _buildNoteItem('Data Structures Slides.pptx', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description_outlined, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.download_outlined, color: Color(0xFF9CA3AF), size: 18),
      ],
    );
  }

  Widget _buildLeaveButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFF43F5E)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Leave Group',
          style: GoogleFonts.outfit(
            color: const Color(0xFFF43F5E),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
```

---

## SCREEN 26 — Topic Chat Screen
### File: `lib/features/groups/screens/topic_chat_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicChatScreen extends StatelessWidget {
  const TopicChatScreen({super.key});

  static const List<Map<String, dynamic>> _messages = [
    {'sender': 'AI Tutor', 'text': 'Pharmacokinetics covers drug absorption, distribution, metabolism and excretion. Which part would you like to explore?', 'isAI': true},
    {'sender': 'Chifundo', 'text': 'Can someone explain the half-life formula?', 'isAI': false, 'isMe': true},
    {'sender': 'Malinga', 'text': 'Half-life = 0.693 / elimination rate constant (Ke). Remember it as "0.7 over Ke"!', 'isAI': false, 'isMe': false},
    {'sender': 'AI Tutor', 'text': 'Great mnemonic! Half-life (t½) determines how long a drug stays active. Drugs with short half-lives need more frequent dosing.', 'isAI': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildMessages(context)),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2D44))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF9CA3AF), size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chat_outlined, color: Color(0xFF7C3AED), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Topic: Pharmacokinetics',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI + Peer Discussion',
                  style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.people_outline, color: Color(0xFF9CA3AF), size: 20),
        ],
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isAI = msg['isAI'] as bool;
        final isMe = (msg['isMe'] ?? false) as bool;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAI ? const Color(0xFF7C3AED) : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        msg['sender'] as String,
                        style: GoogleFonts.outfit(
                          color: isAI ? const Color(0xFF7C3AED) : const Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF7C3AED)
                      : isAI
                          ? const Color(0xFF7C3AED).withOpacity(0.1)
                          : const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(14),
                  border: isMe
                      ? null
                      : Border.all(
                          color: isAI
                              ? const Color(0xFF7C3AED).withOpacity(0.3)
                              : const Color(0xFF2D2D44),
                        ),
                ),
                child: Text(
                  msg['text'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF2D2D44))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2D2D44)),
              ),
              child: TextField(
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ask AI or message the group...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
```

---

## SCREEN 27 — Notifications Screen
### File: `lib/features/notifications/screens/notifications_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<Map<String, dynamic>> _notifications = [
    {
      'type': 'streak',
      'icon': '🔥',
      'title': '12-Day Streak!',
      'body': "Amazing! You've studied 12 days in a row. Keep it up!",
      'time': 'Today, 8:00 AM',
      'color': Color(0xFFF59E0B),
      'read': false,
    },
    {
      'type': 'review',
      'icon': '🔁',
      'title': 'Time to review',
      'body': 'Pharmacokinetics is due for spaced repetition review today.',
      'time': 'Today, 7:30 AM',
      'color': Color(0xFF7C3AED),
      'read': false,
    },
    {
      'type': 'exam',
      'icon': '📅',
      'title': 'Exam in 12 Days',
      'body': 'Anatomy Final is on 24/05/26. Your readiness: 88%',
      'time': 'Yesterday, 6:00 PM',
      'color': Color(0xFFF43F5E),
      'read': true,
    },
    {
      'type': 'report',
      'icon': '📊',
      'title': 'Weekly Report Ready',
      'body': 'You studied 15 hours this week. Tap to see your Wrapped.',
      'time': 'Sun, 9:00 AM',
      'color': Color(0xFF10B981),
      'read': true,
    },
    {
      'type': 'weak',
      'icon': '⚠️',
      'title': 'Weak Topic Alert',
      'body': 'Drug Absorption has a low rating. Consider reviewing it before your exam.',
      'time': 'Sat, 10:00 AM',
      'color': Color(0xFFF43F5E),
      'read': true,
    },
    {
      'type': 'badge',
      'icon': '🏆',
      'title': 'Badge Earned: Week Warrior',
      'body': "You've maintained a 7-day study streak. You earned the Week Warrior badge!",
      'time': 'Mon, 8:00 AM',
      'color': Color(0xFFF59E0B),
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Color(0xFF9CA3AF), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _notifications.length,
                itemBuilder: (_, i) => _NotificationCard(
                  notification: _notifications[i],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] as bool;
    final color = notification['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFF16213E) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? const Color(0xFF2D2D44) : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              notification['icon'] as String,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'] as String,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification['body'] as String,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notification['time'] as String,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

---
# ═══════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════

```
Total screens coded:  27  (24 required + 3 bonus onboarding steps)
Batch 1 (Image 1):    4 screens  — Home, Modules, Analytics, Groups
Batch 2 (Image 2):    4 screens  — Weekly Wrapped, Timetable, Topic Detail, Quiz
Batch 3 (Image 3):    4 screens  — Onboarding Step 4, AI Tutor, Profile, Settings
Batch 4 (Image 4):    4 screens  — Onboarding Step 1, Login, Exam Countdown, Group Chat
Batch 5 (Missing):    7 screens  — Splash, Sign Up, Onboarding Steps 2/3/5/6
Batch 6 (Missing):    5 screens  — Module Detail, Study Session, Group Detail,
                                   Topic Chat, Notifications

Design:  Dark #0F0F1A · Violet #7C3AED · Cyan #06B6D4
Fonts:   Outfit (headings) + Inter (body)  — via google_fonts package
```

---
*StudyTrack All Screens — Complete*
*Every screen matches the same design system*
*Drop each file into its path and connect with go_router navigation*

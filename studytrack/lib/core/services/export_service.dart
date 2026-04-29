import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../models/weekly_report_model.dart';

class ExportService {
  Future<File> createWeeklyReportPdf({
    required String studentName,
    required String course,
    required int yearLevel,
    required int totalTopics, required int masteredTopics, required int streakCount, WeeklyReportModel? weeklyReport,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'StudyTrack Weekly Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Generated: ${now.toIso8601String()}'),
              pw.SizedBox(height: 18),
              pw.Text('Student: $studentName'),
              pw.Text('Course: $course'),
              pw.Text('Year Level: $yearLevel'),
              pw.SizedBox(height: 18),
              pw.Text(
                'Progress Snapshot',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Bullet(text: 'Total topics: $totalTopics'),
              pw.Bullet(text: 'Mastered topics: $masteredTopics'),
              pw.Bullet(text: 'Current streak: $streakCount'),
              pw.SizedBox(height: 16),
              if (weeklyReport != null) ...[
                pw.Text(
                  'Weekly Report Metrics',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Bullet(
                  text:
                      'Week: ${weeklyReport.weekStart.toIso8601String().split('T').first} to ${weeklyReport.weekEnd.toIso8601String().split('T').first}',
                ),
                pw.Bullet(
                  text:
                      'Sessions completed: ${weeklyReport.sessionsCompleted}/${weeklyReport.sessionsPlanned}',
                ),
                pw.Bullet(
                  text:
                      'Topics studied: ${weeklyReport.topicsStudied}/${weeklyReport.topicsPlanned}',
                ),
                pw.Bullet(
                  text:
                      'Average rating: ${(weeklyReport.averageRating ?? 0).toStringAsFixed(1)}/10',
                ),
                if ((weeklyReport.aiSummary ?? '').trim().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10),
                    child: pw.Text('AI Summary: ${weeklyReport.aiSummary}'),
                  ),
              ],
            ],
          ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      p.join(
        directory.path,
        'studytrack_weekly_report_${now.millisecondsSinceEpoch}.pdf',
      ),
    );

    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  Future<File> createBackupJson({
    required String userId,
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> modules,
    required List<Map<String, dynamic>> exams,
  }) async {
    final now = DateTime.now();
    final directory = await getTemporaryDirectory();
    final file = File(
      p.join(
        directory.path,
        'studytrack_backup_${userId}_${now.millisecondsSinceEpoch}.json',
      ),
    );

    final payload = {
      'exported_at': now.toIso8601String(),
      'user_id': userId,
      'profile': profile,
      'modules': modules,
      'exams': exams,
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file;
  }

  Future<void> shareFileToGoogleDrive({
    required File file,
    required String message,
  }) async {
    await SharePlus.instance.share(
      ShareParams(text: message, files: [XFile(file.path)]),
    );
  }
}

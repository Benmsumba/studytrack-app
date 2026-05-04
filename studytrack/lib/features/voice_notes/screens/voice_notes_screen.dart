import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../widgets/voice_note_recorder_widget.dart';

class VoiceNotesScreen extends StatelessWidget {
  const VoiceNotesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    appBar: AppBar(
      backgroundColor: AppColors.backgroundDark,
      title: Text('Voice Notes', style: AppTextStyles.headingSmall),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Capture a quick voice note and save the transcription locally.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          const VoiceNoteRecorderWidget(
            topicId: null,
            allowUpload: false,
            title: 'Voice Note',
            subtitle: 'Record a quick revision note',
          ),
        ],
      ),
    ),
  );
}

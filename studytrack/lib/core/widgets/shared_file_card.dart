import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class SharedFileCard extends StatelessWidget {
  const SharedFileCard({
    required this.fileName,
    required this.fileType,
    this.uploadedBy,
    this.uploadedAt,
    this.fileSize,
    this.onTap,
    this.onDownload,
    this.onDelete,
    super.key,
  });

  final String fileName;
  final FileType fileType;
  final String? uploadedBy;
  final DateTime? uploadedAt;
  final String? fileSize;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  IconData get _fileIcon => switch (fileType) {
    FileType.pdf => Icons.picture_as_pdf,
    FileType.image => Icons.image,
    FileType.video => Icons.video_library,
    FileType.audio => Icons.audio_file,
    FileType.document => Icons.description,
    FileType.spreadsheet => Icons.table_chart,
    FileType.archive => Icons.folder_zip,
    FileType.other => Icons.insert_drive_file,
  };

  Color get _fileColor => switch (fileType) {
    FileType.pdf => const Color(0xFFD32F2F),
    FileType.image => const Color(0xFF4CAF50),
    FileType.video => const Color(0xFF2196F3),
    FileType.audio => const Color(0xFFFF9800),
    FileType.document => const Color(0xFF1976D2),
    FileType.spreadsheet => const Color(0xFF388E3C),
    FileType.archive => const Color(0xFF7B1FA2),
    FileType.other => AppColors.info,
  };

  String _formatUploadTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _fileColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_fileIcon, color: _fileColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (uploadedBy != null || uploadedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      '${uploadedBy ?? 'Unknown'} • ${_formatUploadTime(uploadedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (fileSize != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      fileSize!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onDownload != null || onDelete != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'download' && onDownload != null) {
                  onDownload!();
                } else if (value == 'delete' && onDelete != null) {
                  onDelete!();
                }
              },
              itemBuilder: (context) => [
                if (onDownload != null)
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 12),
                        Text('Download'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
              ],
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    ),
  );
}

enum FileType {
  pdf,
  image,
  video,
  audio,
  document,
  spreadsheet,
  archive,
  other,
}

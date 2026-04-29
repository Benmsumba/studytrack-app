class UploadedNoteModel {
  factory UploadedNoteModel.fromJson(Map<String, dynamic> json) =>
      UploadedNoteModel(
        id: json['id'] as String,
        topicId: json['topic_id'] as String,
        userId: json['user_id'] as String,
        fileName: json['file_name'] as String,
        fileUrl: json['file_url'] as String,
        fileType: json['file_type'] as String,
        isSharedWithGroup: json['is_shared_with_group'] as bool? ?? false,
        processingStatus: json['processing_status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  const UploadedNoteModel({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.isSharedWithGroup,
    required this.processingStatus,
    required this.createdAt,
  });

  final String id;
  final String topicId;
  final String userId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final bool isSharedWithGroup;
  final String processingStatus;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic_id': topicId,
    'user_id': userId,
    'file_name': fileName,
    'file_url': fileUrl,
    'file_type': fileType,
    'is_shared_with_group': isSharedWithGroup,
    'processing_status': processingStatus,
    'created_at': createdAt.toIso8601String(),
  };

  UploadedNoteModel copyWith({
    String? id,
    String? topicId,
    String? userId,
    String? fileName,
    String? fileUrl,
    String? fileType,
    bool? isSharedWithGroup,
    String? processingStatus,
    DateTime? createdAt,
  }) => UploadedNoteModel(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    userId: userId ?? this.userId,
    fileName: fileName ?? this.fileName,
    fileUrl: fileUrl ?? this.fileUrl,
    fileType: fileType ?? this.fileType,
    isSharedWithGroup: isSharedWithGroup ?? this.isSharedWithGroup,
    processingStatus: processingStatus ?? this.processingStatus,
    createdAt: createdAt ?? this.createdAt,
  );
}

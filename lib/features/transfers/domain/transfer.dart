enum TransferType { upload, download }

enum TransferStatus { queued, running, paused, completed, failed }

class Transfer {
  const Transfer({
    required this.id,
    required this.name,
    required this.type,
    this.progress = 0,
    this.status = TransferStatus.queued,
    this.message,
    this.url,
  });

  final String id;
  final String name;
  final TransferType type;
  final double progress;
  final TransferStatus status;
  final String? message;
  final String? url;

  Transfer copyWith({
    double? progress,
    TransferStatus? status,
    String? message,
    String? url,
  }) => Transfer(
    id: id,
    name: name,
    type: type,
    progress: progress ?? this.progress,
    status: status ?? this.status,
    message: message ?? this.message,
    url: url ?? this.url,
  );
}

class TransferFile {
  const TransferFile({
    required this.name,
    this.url,
    this.type,
    this.uploadedAt,
    this.sizeBytes,
    this.sizeText,
  });

  final String name;
  final String? url;
  final String? type;
  final DateTime? uploadedAt;
  final int? sizeBytes;
  final String? sizeText;

  static TransferFile? tryParse(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return TransferFile(name: value);
    }
    if (value is! Map) return null;

    final name = value['name'] ?? value['filename'] ?? value['file'];
    final url = value['url'] ?? value['download_url'];
    if (name is! String || name.isEmpty) return null;
    final type = value['type'] ?? value['mime_type'] ?? value['content_type'];
    final uploadedAt = value['uploaded_at'] ?? value['uploadedAt'];
    final size = value['size'] ?? value['file_size'] ?? value['size_bytes'];
    final sizeBytes = size is num ? size.toInt() : int.tryParse('$size');
    final sizeText = sizeBytes == null && size is String && size.isNotEmpty
        ? size
        : null;

    return TransferFile(
      name: name,
      url: url is String ? url : null,
      type: type is String ? type : null,
      uploadedAt: uploadedAt is String ? DateTime.tryParse(uploadedAt) : null,
      sizeBytes: sizeBytes,
      sizeText: sizeText,
    );
  }
}

String? fileSizeLabel(TransferFile file) {
  if (file.sizeText != null) return file.sizeText;
  final bytes = file.sizeBytes;
  if (bytes == null) return null;
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String? uploadedTimeLabel(DateTime? uploadedAt) {
  if (uploadedAt == null) return null;
  final date = uploadedAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final uploadedDay = DateTime(date.year, date.month, date.day);
  final difference = today.difference(uploadedDay).inDays;

  if (difference == 0) return 'Uploaded today';
  if (difference == 1) return 'Uploaded yesterday';
  return 'Uploaded ${date.month}/${date.day}/${date.year}';
}

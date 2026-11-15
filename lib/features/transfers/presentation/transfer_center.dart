import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/features/transfers/domain/transfer.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/providers/transfer_providers.dart';

class TransferList extends StatelessWidget {
  const TransferList({super.key, this.showEmptyMessage = true, this.type});

  final bool showEmptyMessage;
  final TransferType? type;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final transfers = ref
            .watch(transferControllerProvider)
            .where((transfer) => type == null || transfer.type == type)
            .toList();
        if (transfers.isEmpty && showEmptyMessage) {
          return const Text(
            'No recent transfers',
            style: TextStyle(color: Color(0xFF52705A)),
          );
        }
        if (transfers.isEmpty) return const SizedBox.shrink();
        return Column(
          children: transfers
              .take(5)
              .map((transfer) => _TransferTile(transfer: transfer))
              .toList(),
        );
      },
    );
  }
}

class TransferFilesActivity extends StatelessWidget {
  const TransferFilesActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final files = ref.watch(remoteFilesProvider);
        return files.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => const Text(
            'Could not load recent files.',
            style: TextStyle(color: Color(0xFFB3261E)),
          ),
          data: (files) {
            if (files.isEmpty) {
              return const Text(
                'No files available',
                style: TextStyle(color: Color(0xFF52705A)),
              );
            }
            return Column(
              children: files
                  .take(5)
                  .map(
                    (file) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _remoteFileIcon(file),
                        color: Color(0xFF3B8B4D),
                      ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _fileMetadata(file),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

Widget? _fileMetadata(TransferFile file) {
  final metadata = [
    uploadedTimeLabel(file.uploadedAt),
    fileSizeLabel(file),
  ].whereType<String>().join(' • ');
  return metadata.isEmpty
      ? null
      : Text(metadata, style: const TextStyle(color: Color(0xFF52705A)));
}

IconData _remoteFileIcon(TransferFile file) {
  final type = file.type?.toLowerCase() ?? '';
  if (type.startsWith('image/')) return Icons.image_outlined;
  if (type.startsWith('video/')) return Icons.video_library_outlined;
  if (type == 'application/pdf') return Icons.picture_as_pdf_outlined;
  if (type.contains('zip') || type.contains('compressed')) {
    return Icons.inventory_2_outlined;
  }
  if (type.contains('csv') || type.contains('spreadsheet')) {
    return Icons.table_chart_outlined;
  }

  final extension = file.name.split('.').last.toLowerCase();
  if (extension == 'pdf') return Icons.picture_as_pdf_outlined;
  if (extension == 'zip' || extension == 'rar') {
    return Icons.inventory_2_outlined;
  }
  if (extension == 'csv' || extension == 'xls' || extension == 'xlsx') {
    return Icons.table_chart_outlined;
  }
  if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
    return Icons.image_outlined;
  }
  if (extension == 'mp4' || extension == 'mov') {
    return Icons.video_library_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({required this.transfer});
  final Transfer transfer;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final active =
            transfer.status == TransferStatus.running ||
            transfer.status == TransferStatus.paused;
        final status = switch (transfer.status) {
          TransferStatus.running => '${(transfer.progress * 100).round()}%',
          TransferStatus.completed => 'Completed',
          TransferStatus.paused => 'Paused',
          TransferStatus.failed => 'Failed',
          TransferStatus.queued => 'Queued',
        };
        if (active) {
          final action = transfer.status == TransferStatus.paused
              ? 'Paused'
              : transfer.type == TransferType.upload
              ? 'Uploading'
              : 'Downloading';
          final percentage = (transfer.progress * 100).round();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE3F4)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(
                        0xFF9BC7FF,
                      ).withValues(alpha: .15),
                      child: Icon(
                        transfer.type == TransferType.upload
                            ? Icons.upload
                            : Icons.download,
                        color: const Color(0xFF5064D8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transfer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action,
                            style: const TextStyle(
                              color: Color(0xFF52705A),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Color(0xFF5064D8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(transferControllerProvider.notifier)
                          .togglePause(transfer),
                      tooltip: transfer.status == TransferStatus.paused
                          ? 'Resume'
                          : 'Pause',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD8E0F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(38, 38),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        transfer.status == TransferStatus.paused
                            ? Icons.play_arrow_outlined
                            : Icons.pause_outlined,
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(transferControllerProvider.notifier)
                          .cancel(transfer.id),
                      tooltip: 'Cancel',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD8E0F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(38, 38),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: transfer.progress),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$percentage% complete',
                      style: const TextStyle(
                        color: Color(0xFF52705A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF9BC7FF).withValues(alpha: .15),
            child: Icon(
              transfer.type == TransferType.upload
                  ? Icons.upload
                  : Icons.download,
              color: const Color(0xFF9BC7FF),
            ),
          ),
          title: Text(
            transfer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(transfer.message ?? status),
          trailing: Text(status, style: const TextStyle(fontSize: 12)),
        );
      },
    );
  }
}

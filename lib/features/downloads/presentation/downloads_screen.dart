import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/features/transfers/domain/transfer.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/providers/transfer_providers.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final files = ref.watch(remoteFilesProvider);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(remoteFilesProvider);
              await ref.read(remoteFilesProvider.future);
            },
            child: files.when(
              loading: () => ListView(
                children: [
                  SizedBox(
                    height: 500,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (error, stackTrace) => ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 110),
                children: const [
                  Text(
                    'Could not load files. Pull to retry.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
              data: (files) => ListView.builder(
                padding: const EdgeInsets.only(bottom: 110),
                itemCount: files.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) return _FilesHeader(count: files.length);
                  if (index == 1 && files.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'No files available',
                          style: TextStyle(color: Color(0xFF52705A)),
                        ),
                      ),
                    );
                  }
                  if (index == 1) return const SizedBox(height: 8);

                  final file = files[index - 2];
                  return _TransferFileTile(
                    file: file,
                    transfer: _downloadFor(
                      ref.watch(transferControllerProvider),
                      file.name,
                    ),
                    onDownload: () => ref
                        .read(transferControllerProvider.notifier)
                        .download(file),
                    onPause: () {
                      final transfer = _downloadFor(
                        ref.read(transferControllerProvider),
                        file.name,
                      );
                      if (transfer != null) {
                        ref
                            .read(transferControllerProvider.notifier)
                            .togglePause(transfer);
                      }
                    },
                    onCancel: () {
                      final transfer = _downloadFor(
                        ref.read(transferControllerProvider),
                        file.name,
                      );
                      if (transfer != null) {
                        ref
                            .read(transferControllerProvider.notifier)
                            .cancel(transfer.id);
                      }
                    },
                    onDelete: () async {
                      await ref
                          .read(transferControllerProvider.notifier)
                          .delete(file);
                      ref.invalidate(remoteFilesProvider);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilesHeader extends StatelessWidget {
  const _FilesHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Downloads',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'file' : 'files'} available',
            style: const TextStyle(color: Color(0xFF52705A)),
          ),
        ],
      ),
    );
  }
}

class _TransferFileTile extends StatelessWidget {
  const _TransferFileTile({
    required this.file,
    required this.transfer,
    required this.onDownload,
    required this.onPause,
    required this.onCancel,
    required this.onDelete,
  });

  final TransferFile file;
  final Transfer? transfer;
  final VoidCallback onDownload;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final extension = _extension(file.name);
    final active =
        transfer?.status == TransferStatus.running ||
        transfer?.status == TransferStatus.paused;
    final completed = transfer?.status == TransferStatus.completed;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD3E8D6))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _FileIcon(file: file),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    _fileMetadata(file, completed),
                  ],
                ),
              ),
              _ExtensionBadge(extension: extension),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDownload,
                tooltip: active ? 'Downloading' : 'Download',
                icon: Icon(
                  active ? Icons.downloading : Icons.download_outlined,
                  color: const Color(0xFF9BC7FF),
                ),
              ),
              IconButton(
                onPressed: () => onDelete(),
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        transfer?.status == TransferStatus.paused
                            ? 'Paused'
                            : 'Downloading',
                        style: TextStyle(
                          color: Color(0xFF5064D8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${((transfer?.progress ?? 0) * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xFF5064D8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: transfer?.progress),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${((transfer?.progress ?? 0) * 100).round()}% complete',
                      style: const TextStyle(
                        color: Color(0xFF52705A),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: onPause,
                        tooltip: transfer?.status == TransferStatus.paused
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
                          transfer?.status == TransferStatus.paused
                              ? Icons.play_arrow_outlined
                              : Icons.pause_outlined,
                        ),
                      ),
                      IconButton(
                        onPressed: onCancel,
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.file});

  final TransferFile file;

  @override
  Widget build(BuildContext context) {
    final color = _fileColor(file);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_fileIcon(file), color: color, size: 28),
    );
  }
}

class _ExtensionBadge extends StatelessWidget {
  const _ExtensionBadge({required this.extension});

  final String extension;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EC),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        extension,
        style: const TextStyle(fontSize: 11, color: Color(0xFF52705A)),
      ),
    );
  }
}

Transfer? _downloadFor(List<Transfer> transfers, String name) {
  for (final transfer in transfers) {
    if (transfer.type == TransferType.download && transfer.name == name) {
      return transfer;
    }
  }
  return null;
}

String _extension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return 'FILE';
  return name.substring(dot + 1).toUpperCase();
}

Widget _fileMetadata(TransferFile file, bool completed) {
  final metadata = [
    if (completed) 'Download completed',
    uploadedTimeLabel(file.uploadedAt),
    fileSizeLabel(file),
  ].whereType<String>().join(' • ');
  return Text(
    metadata,
    style: const TextStyle(color: Color(0xFF52705A), fontSize: 12),
  );
}

IconData _fileIcon(TransferFile file) {
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

  final extension = _extension(file.name);
  switch (extension) {
    case 'PDF':
      return Icons.picture_as_pdf_outlined;
    case 'ZIP':
    case 'RAR':
      return Icons.inventory_2_outlined;
    case 'CSV':
    case 'XLS':
    case 'XLSX':
      return Icons.table_chart_outlined;
    case 'JPG':
    case 'JPEG':
    case 'PNG':
      return Icons.image_outlined;
    case 'MP4':
    case 'MOV':
      return Icons.video_library_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

Color _fileColor(TransferFile file) {
  final type = file.type?.toLowerCase() ?? '';
  if (type.startsWith('image/')) return Colors.lightBlueAccent;
  if (type.startsWith('video/')) return Colors.deepPurpleAccent;
  if (type == 'application/pdf') return Colors.redAccent;
  if (type.contains('zip') || type.contains('compressed')) {
    return Colors.orangeAccent;
  }
  if (type.contains('csv') || type.contains('spreadsheet')) {
    return Colors.greenAccent;
  }

  final extension = _extension(file.name);
  switch (extension) {
    case 'PDF':
      return Colors.redAccent;
    case 'ZIP':
    case 'RAR':
      return Colors.orangeAccent;
    case 'CSV':
    case 'XLS':
    case 'XLSX':
      return Colors.greenAccent;
    case 'JPG':
    case 'JPEG':
    case 'PNG':
      return Colors.lightBlueAccent;
    case 'MP4':
    case 'MOV':
      return Colors.deepPurpleAccent;
    default:
      return const Color(0xFF9BC7FF);
  }
}

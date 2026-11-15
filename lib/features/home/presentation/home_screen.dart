import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/domain/transfer.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/presentation/transfer_center.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/providers/transfer_providers.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final files = ref.watch(remoteFilesProvider);
          final transfers = ref.watch(transferControllerProvider);
          final uploading = transfers
              .where(
                (transfer) =>
                    transfer.type == TransferType.upload &&
                    transfer.status == TransferStatus.running,
              )
              .length;
          final downloading = transfers
              .where(
                (transfer) =>
                    transfer.type == TransferType.download &&
                    transfer.status == TransferStatus.running,
              )
              .length;

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
              error: (error, stackTrace) => _Dashboard(
                total: null,
                uploading: 0,
                downloading: 0,
                completed: null,
                onNewUpload: () => ref
                    .read(transferControllerProvider.notifier)
                    .pickAndUpload(),
              ),
              data: (remoteFiles) => _Dashboard(
                total: remoteFiles.length + uploading + downloading,
                uploading: uploading,
                downloading: downloading,
                completed: remoteFiles.length,
                onNewUpload: () => ref
                    .read(transferControllerProvider.notifier)
                    .pickAndUpload(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.total,
    required this.uploading,
    required this.downloading,
    required this.completed,
    required this.onNewUpload,
  });

  final int? total;
  final int uploading;
  final int downloading;
  final int? completed;
  final VoidCallback onNewUpload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QuickDrop dashboard',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Monitor and manage all your file transfers.',
                    style: TextStyle(color: Color(0xFF52705A)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  width: cardWidth,
                  label: 'Total transfers',
                  value: total,
                  detail: 'Files in workspace',
                  icon: Icons.grid_view_rounded,
                  color: const Color(0xFF5064D8),
                  iconBackground: const Color(0xFFE9EDFF),
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Uploading',
                  value: uploading,
                  detail: 'In progress',
                  icon: Icons.cloud_upload_outlined,
                  color: const Color(0xFF2388C9),
                  iconBackground: const Color(0xFFE4F3FF),
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Downloading',
                  value: downloading,
                  detail: 'In progress',
                  icon: Icons.download_outlined,
                  color: const Color(0xFF7651D8),
                  iconBackground: const Color(0xFFF0E9FF),
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Completed',
                  value: completed,
                  detail: 'Server files',
                  icon: Icons.check,
                  color: const Color(0xFF239B72),
                  iconBackground: const Color(0xFFE1F6ED),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        const Text(
          'Recent activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const TransferList(showEmptyMessage: false),
        const TransferFilesActivity(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.iconBackground,
  });

  final double width;
  final String label;
  final int? value;
  final String detail;
  final IconData icon;
  final Color color;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8EBDD)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF52705A),
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value?.toString() ?? '-',
              style: const TextStyle(
                color: Color(0xFF183B25),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(detail, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

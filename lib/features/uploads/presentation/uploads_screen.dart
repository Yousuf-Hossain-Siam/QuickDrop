import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/features/transfers/domain/transfer.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/presentation/transfer_center.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/providers/transfer_providers.dart';

class UploadsScreen extends StatelessWidget {
  const UploadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(remoteFilesProvider);
            await ref.read(remoteFilesProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
            children: [
              const Text(
                'Import data',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Color(0xFFB7D9BE)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.file_upload_outlined,
                      size: 64,
                      color: Color(0xFF9BC7FF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select a file to upload',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CSV, images, and video files are supported.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF52705A)),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final uploading = ref
                              .watch(transferControllerProvider)
                              .any(
                                (transfer) =>
                                    transfer.type == TransferType.upload &&
                                    transfer.status == TransferStatus.running,
                              );
                          return ElevatedButton.icon(
                            onPressed: uploading
                                ? null
                                : () => ref
                                      .read(transferControllerProvider.notifier)
                                      .pickAndUpload(),
                            icon: uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.folder_open),
                            label: Text(
                              uploading ? 'Uploading...' : 'Choose file',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Upload activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const TransferList(
                showEmptyMessage: false,
                type: TransferType.upload,
              ),
              const TransferFilesActivity(),
            ],
          ),
        ),
      ),
    );
  }
}

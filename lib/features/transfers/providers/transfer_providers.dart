import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/core/notifications/notification_service.dart';
import 'package:flutter_pos_background_upload_download/features/auth/providers/auth_providers.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/data/transfer_repository.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/domain/transfer.dart';

final transferRepositoryProvider = Provider<TransferRepository>(
  (ref) => TransferRepository(ref.watch(apiClientProvider)),
);

final remoteFilesProvider = FutureProvider.autoDispose<List<TransferFile>>(
  (ref) => ref.watch(transferRepositoryProvider).listFiles(),
);

final transferControllerProvider =
    NotifierProvider<TransferController, List<Transfer>>(
      TransferController.new,
    );

class TransferController extends Notifier<List<Transfer>> {
  final Map<String, CancelToken> _tokens = {};
  final Map<String, File> _uploadFiles = {};
  final Map<String, int> _lastNotificationProgress = {};

  TransferRepository get _repository => ref.read(transferRepositoryProvider);

  @override
  List<Transfer> build() {
    ref.onDispose(() {
      for (final token in _tokens.values) {
        token.cancel('Transfer controller disposed');
      }
      _tokens.clear();
      _uploadFiles.clear();
      _lastNotificationProgress.clear();
    });
    return [];
  }

  Future<void> pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    final path = result?.files.single.path;
    if (path == null) return;
    final file = File(path);
    final id = 'upload-${DateTime.now().microsecondsSinceEpoch}';
    await _runUpload(id, file);
  }

  Future<void> _runUpload(String id, File file, {Transfer? existing}) async {
    final transfer =
        existing ??
        Transfer(
          id: id,
          name: file.uri.pathSegments.last,
          type: TransferType.upload,
        );
    if (existing == null) {
      state = [transfer, ...state];
    }
    _uploadFiles[id] = file;
    _lastNotificationProgress.remove(id);
    final token = CancelToken();
    _tokens[id] = token;
    _update(
      id,
      transfer.copyWith(
        progress: existing == null ? 0 : transfer.progress,
        status: TransferStatus.running,
      ),
    );
    try {
      final url = await _repository.upload(file, (sent, total) {
        if (token.isCancelled) return;
        if (total > 0) {
          final current = _find(id);
          if (current == null) return;
          final progress = sent / total;
          _update(
            id,
            current.copyWith(
              progress: progress > current.progress
                  ? progress
                  : current.progress,
              status: TransferStatus.running,
            ),
          );
        }
        _notifyProgress(
          id: id,
          title: 'Uploading ${transfer.name}',
          progress: total > 0 ? (sent / total * 100).round() : 0,
        );
      }, token);
      _update(
        id,
        transfer.copyWith(
          progress: 1,
          status: TransferStatus.completed,
          url: url,
        ),
      );
      ref.invalidate(remoteFilesProvider);
      await NotificationService.instance.showResult(
        id: id.hashCode,
        title: 'Upload complete',
        body: transfer.name,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        final current = _find(id);
        if (current == null) return;
        _update(
          id,
          current.copyWith(
            status: TransferStatus.paused,
            message: 'Paused by user',
          ),
        );
      } else {
        _update(
          id,
          transfer.copyWith(
            status: TransferStatus.failed,
            message: 'Upload failed. Tap retry.',
          ),
        );
      }
    } catch (_) {
      _update(
        id,
        transfer.copyWith(
          status: TransferStatus.failed,
          message: 'Upload failed. Tap retry.',
        ),
      );
    } finally {
      if (identical(_tokens[id], token)) {
        _tokens.remove(id);
      }
      final current = _find(id);
      if (current == null ||
          (current.status != TransferStatus.paused &&
              current.status != TransferStatus.failed)) {
        _uploadFiles.remove(id);
      }
      _lastNotificationProgress.remove(id);
    }
  }

  Future<void> download(TransferFile file) async {
    final id = 'download-${DateTime.now().microsecondsSinceEpoch}';
    final transfer = Transfer(
      id: id,
      name: file.name,
      type: TransferType.download,
      url: file.url,
    );
    state = [transfer, ...state];
    await _runDownload(id, file, transfer);
  }

  Future<void> _runDownload(
    String id,
    TransferFile file,
    Transfer transfer,
  ) async {
    final resume = transfer.status == TransferStatus.paused;
    final token = CancelToken();
    _tokens[id] = token;
    _lastNotificationProgress.remove(id);
    _update(
      id,
      transfer.copyWith(
        progress: resume ? transfer.progress : 0,
        status: TransferStatus.running,
      ),
    );
    try {
      await _repository.download(
        file.name,
        (received, total) {
          if (token.isCancelled) return;
          if (total > 0) {
            final current = _find(id);
            if (current == null) return;
            _update(
              id,
              current.copyWith(
                progress: received / total,
                status: TransferStatus.running,
              ),
            );
          }
          _notifyProgress(
            id: id,
            title: 'Downloading ${file.name}',
            progress: total > 0 ? (received / total * 100).round() : 0,
          );
        },
        token,
        resume: resume,
      );
      _update(
        id,
        transfer.copyWith(progress: 1, status: TransferStatus.completed),
      );
      await NotificationService.instance.showResult(
        id: id.hashCode,
        title: 'Download complete',
        body: 'Saved ${file.name} to Downloads/QuickDrop',
      );
    } on DioException catch (error) {
      final current = _find(id);
      if (current == null) return;
      _update(
        id,
        current.copyWith(
          status: CancelToken.isCancel(error)
              ? TransferStatus.paused
              : TransferStatus.failed,
          message: CancelToken.isCancel(error)
              ? 'Paused by user'
              : 'Download failed. Tap retry.',
        ),
      );
    } catch (_) {
      _update(
        id,
        transfer.copyWith(
          status: TransferStatus.failed,
          message: 'Download failed. Tap retry.',
        ),
      );
    } finally {
      if (identical(_tokens[id], token)) {
        _tokens.remove(id);
      }
      _lastNotificationProgress.remove(id);
    }
  }

  Future<void> togglePause(Transfer transfer) async {
    if (transfer.status == TransferStatus.running) {
      final token = _tokens[transfer.id];
      if (token == null) {
        _update(
          transfer.id,
          transfer.copyWith(
            status: TransferStatus.paused,
            message: 'Paused by user',
          ),
        );
        return;
      }
      token.cancel('Paused by user');
      return;
    }
    if (transfer.status != TransferStatus.paused) return;

    if (transfer.type == TransferType.upload) {
      final file = _uploadFiles[transfer.id];
      if (file != null) {
        await _runUpload(transfer.id, file, existing: transfer);
      }
      return;
    }

    await _runDownload(
      transfer.id,
      TransferFile(name: transfer.name, url: transfer.url),
      transfer,
    );
  }

  void cancel(String id) {
    _tokens[id]?.cancel();
    _uploadFiles.remove(id);
    state = state.where((transfer) => transfer.id != id).toList();
  }

  Future<void> retry(Transfer transfer) async {
    if (transfer.type == TransferType.upload) {
      final file = _uploadFiles[transfer.id];
      if (file != null) {
        await _runUpload(transfer.id, file, existing: transfer);
      }
      return;
    }
    await download(TransferFile(name: transfer.name, url: transfer.url));
  }

  Future<void> delete(TransferFile file) => _repository.delete(file.name);

  void _update(String id, Transfer value) {
    state = [
      for (final item in state)
        if (item.id == id) value else item,
    ];
  }

  void _notifyProgress({
    required String id,
    required String title,
    required int progress,
  }) {
    final clamped = progress.clamp(0, 100);
    final previous = _lastNotificationProgress[id];
    if (previous != null && clamped != 100 && clamped - previous < 2) {
      return;
    }
    _lastNotificationProgress[id] = clamped;
    unawaited(
      NotificationService.instance
          .showProgress(id: id.hashCode, title: title, progress: clamped)
          .catchError((_) {}),
    );
  }

  Transfer? _find(String id) {
    for (final transfer in state) {
      if (transfer.id == id) return transfer;
    }
    return null;
  }
}

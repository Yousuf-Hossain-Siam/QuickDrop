import 'dart:io';

import 'package:dio/dio.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_pos_background_upload_download/core/constants/api_constants.dart';
import 'package:flutter_pos_background_upload_download/core/network/api_client.dart';
import 'package:flutter_pos_background_upload_download/features/transfers/domain/transfer.dart';

class TransferRepository {
  TransferRepository(this._client);
  final ApiClient _client;

  Future<List<TransferFile>> listFiles() async {
    final response = await _client.dio.get<dynamic>(
      ApiConstants.filesPath,
      options: Options(responseType: ResponseType.json),
    );
    final rawData = response.data;
    final items = rawData is List
        ? rawData
        : rawData is Map
        ? (rawData['files'] ?? rawData['data'] ?? rawData['results'])
        : null;
    if (items is! List) return const [];

    return items.map(TransferFile.tryParse).whereType<TransferFile>().toList();
  }

  Future<String?> upload(
    File file,
    ProgressCallback onProgress,
    CancelToken token,
  ) async {
    final response = await _client.dio.post(
      ApiConstants.uploadPath,
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      }),
      cancelToken: token,
      onSendProgress: onProgress,
    );
    final data = response.data;
    return data is Map ? (data['url'] ?? data['file_url']) as String? : null;
  }

  Future<void> download(
    String name,
    ProgressCallback onProgress,
    CancelToken token, {
    bool resume = false,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _safeFileName(name);
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    final offset = resume && await file.exists() ? await file.length() : 0;
    if (!resume && await file.exists()) {
      await file.delete();
    }
    final response = await _client.dio.download(
      '${ApiConstants.filesPath}?file=${Uri.encodeQueryComponent(name)}',
      file.path,
      cancelToken: token,
      deleteOnError: false,
      fileAccessMode: offset > 0 ? FileAccessMode.append : FileAccessMode.write,
      onReceiveProgress: (received, total) {
        onProgress(offset + received, total > 0 ? offset + total : total);
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: offset > 0 ? {'Range': 'bytes=$offset-'} : null,
      ),
    );
    if (offset > 0 && response.statusCode != 206) {
      throw StateError('The download server did not honor the range request.');
    }
    if (Platform.isAndroid) {
      await MediaStore().saveFile(
        tempFilePath: file.path,
        dirType: DirType.download,
        dirName: DirName.download,
        relativePath: FilePath.root,
      );
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> delete(String name) => _client.dio.delete(
    '${ApiConstants.deletePath}?file=${Uri.encodeQueryComponent(name)}',
  );

  String _safeFileName(String name) {
    final normalized = name.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    if (fileName.isEmpty || fileName == '.' || fileName == '..') {
      throw FormatException('The server returned an invalid file name.');
    }
    return fileName;
  }
}

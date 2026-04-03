import 'dart:async';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({FirebaseStorage? storage, bool enabled = true})
      : _enabled = enabled,
        _storage = enabled ? (storage ?? FirebaseStorage.instance) : null;

  static const Duration _fileReadTimeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(seconds: 45);
  static const Duration _downloadUrlTimeout = Duration(seconds: 20);

  final bool _enabled;
  final FirebaseStorage? _storage;

  Future<String> uploadImage({
    required XFile file,
    required String folder,
    required String ownerId,
  }) async {
    debugPrint(
      'PHOTO DETAIL: uploadImage called for ownerId=$ownerId folder=$folder file=${file.name}',
    );

    try {
      if (!_enabled) {
        debugPrint('PHOTO DETAIL: storage disabled, using preview data uri');
        return _createPreviewDataUri(file).timeout(_fileReadTimeout);
      }

      final extension = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpg';

      debugPrint('PHOTO DETAIL: file bytes read started');
      final bytes = await file.readAsBytes().timeout(_fileReadTimeout);
      debugPrint(
        'PHOTO DETAIL: file bytes read finished (${bytes.length} bytes)',
      );

      // WEB FIX:
      // Chrome/Web-та Firebase Storage putData кейде қатып қалады.
      // Сондықтан web-та upload орнына data uri қайтарамыз,
      // analyze flow тоқтамай жұмыс істесін.
      if (kIsWeb) {
        debugPrint(
          'PHOTO DETAIL: running on web, skipping Firebase Storage upload and using preview data uri',
        );
        final previewUrl = _bytesToDataUri(
          bytes,
          _guessMimeType(extension),
        );
        debugPrint(
          'PHOTO DETAIL: preview data uri generated, length=${previewUrl.length}',
        );
        return previewUrl;
      }

      final path =
          '$folder/$ownerId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      final reference = _storage!.ref(path);

      debugPrint('PHOTO 5: upload started');
      final task = await reference.putData(
        bytes,
        SettableMetadata(contentType: _guessMimeType(extension)),
      ).timeout(_uploadTimeout);
      debugPrint('PHOTO 6: upload finished');

      debugPrint('PHOTO 7: download url started');
      final downloadUrl = await task.ref
          .getDownloadURL()
          .timeout(_downloadUrlTimeout);
      debugPrint('PHOTO 8: download url received');
      debugPrint(
        'PHOTO DETAIL: download url value length=${downloadUrl.length}',
      );

      return downloadUrl;
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('PHOTO DETAIL: upload timeout error: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Timeout болса да flow өлмесін.
      // Фотоны жоғалтпай, preview data uri қайтарамыз.
      try {
        debugPrint(
          'PHOTO DETAIL: timeout fallback -> generating preview data uri',
        );
        return await _createPreviewDataUri(file).timeout(_fileReadTimeout);
      } catch (_) {
        throw Exception('Photo upload timed out. Please try again.');
      }
    } catch (error, stackTrace) {
      debugPrint('PHOTO DETAIL: upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Жалпы қате болса да web/demo flow тоқтап қалмасын.
      try {
        debugPrint(
          'PHOTO DETAIL: error fallback -> generating preview data uri',
        );
        return await _createPreviewDataUri(file).timeout(_fileReadTimeout);
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<String> _createPreviewDataUri(XFile file) async {
    final extension = file.name.contains('.')
        ? file.name.split('.').last
        : 'jpg';
    final bytes = await file.readAsBytes();
    return _bytesToDataUri(bytes, _guessMimeType(extension));
  }

  String _bytesToDataUri(Uint8List bytes, String mimeType) {
    final encoded = base64Encode(bytes);
    return 'data:$mimeType;base64,$encoded';
  }

  String _guessMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
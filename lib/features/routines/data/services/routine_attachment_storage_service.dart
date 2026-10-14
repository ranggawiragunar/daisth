import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/routine_attachment.dart';
import 'routine_attachment_file_service.dart';

class RoutineAttachmentStorageService {
  RoutineAttachmentStorageService({this._storage});

  final FirebaseStorage? _storage;
  FirebaseStorage get storage => _storage ?? FirebaseStorage.instance;

  String objectPath(String uid, RoutineAttachment attachment) =>
      'users/$uid/routine-attachments/${attachment.id}/image.${attachment.mimeType == 'image/png' ? 'png' : 'jpg'}';

  Future<String> uploadIfChanged({
    required String uid,
    required RoutineAttachment attachment,
    required File file,
  }) async {
    final remotePath = objectPath(uid, attachment);
    final reference = storage.ref(remotePath);
    FullMetadata? metadata;
    try {
      metadata = await reference.getMetadata();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    if (metadata?.customMetadata?['sha256'] == attachment.contentSha256 &&
        attachment.contentSha256 != null) {
      return remotePath;
    }
    if (!await file.exists()) {
      throw const FileSystemException('Attachment file is missing.');
    }
    await reference.putFile(
      file,
      SettableMetadata(
        contentType: attachment.mimeType,
        customMetadata: {
          if (attachment.contentSha256 != null)
            'sha256': attachment.contentSha256!,
        },
      ),
    );
    return remotePath;
  }

  Future<Uint8List> download({
    required String uid,
    required String storagePath,
    required int expectedBytes,
  }) async {
    if (!storagePath.startsWith('users/$uid/routine-attachments/')) {
      throw const FormatException('Invalid attachment storage path.');
    }
    final bytes = await storage
        .ref(storagePath)
        .getData(expectedBytes.clamp(1, RoutineAttachment.maxBytes));
    if (bytes == null) {
      throw const FileSystemException('Attachment unavailable.');
    }
    return bytes;
  }

  Future<String> cacheDownloaded({
    required String routineId,
    required String attachmentId,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final support = await getApplicationSupportDirectory();
    final extension = mimeType == 'image/png' ? 'png' : 'jpg';
    final relative = path.join(routineId, '$attachmentId.$extension');
    final file = File(
      path.join(
        support.path,
        RoutineAttachmentFileService.attachmentFolder,
        relative,
      ),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return relative;
  }

  Future<void> deleteAttachment(String uid, String attachmentId) async {
    final folder = storage.ref('users/$uid/routine-attachments/$attachmentId');
    for (final extension in ['jpg', 'png']) {
      try {
        await folder.child('image.$extension').delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }
  }

  Future<void> purgeUserAttachments(String uid) async {
    final root = storage.ref('users/$uid/routine-attachments');
    await _deleteTree(root);
  }

  Future<void> _deleteTree(Reference root) async {
    final listing = await root.listAll();
    for (final item in listing.items) {
      await item.delete();
    }
    for (final prefix in listing.prefixes) {
      await _deleteTree(prefix);
    }
  }
}

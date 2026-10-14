import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/routine_attachment.dart';

class StagedRoutineImage {
  const StagedRoutineImage({
    required this.path,
    required this.originalFileName,
    required this.mimeType,
    required this.byteSize,
    required this.width,
    required this.height,
    required this.sha256,
  });

  final String path;
  final String originalFileName;
  final String mimeType;
  final int byteSize;
  final int width;
  final int height;
  final String sha256;
}

class RoutineAttachmentFileService {
  static const attachmentFolder = 'routine_attachments';
  static const stagingFolder = 'routine_attachment_staging';

  Future<StagedRoutineImage> stageImage({
    required XFile file,
    required String routineId,
  }) async {
    final ext = path.extension(file.path).toLowerCase();
    final keepPng = ext == '.png';
    final bytes = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: RoutineAttachment.maxImageDimension,
      minHeight: RoutineAttachment.maxImageDimension,
      quality: 85,
      format: keepPng ? CompressFormat.png : CompressFormat.jpeg,
      keepExif: false,
    );
    if (bytes == null || bytes.isEmpty) throw const FormatException();
    if (bytes.length > RoutineAttachment.maxBytes) {
      throw const RoutineAttachmentTooLargeException();
    }
    final decoded = await ui.instantiateImageCodec(bytes);
    final frame = await decoded.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();
    decoded.dispose();
    final temp = await getTemporaryDirectory();
    final folder = Directory(path.join(temp.path, stagingFolder, routineId));
    await folder.create(recursive: true);
    final stagedPath = path.join(
      folder.path,
      '${DateTime.now().microsecondsSinceEpoch}-${file.name.hashCode & 0xffff}.${keepPng ? 'png' : 'jpg'}',
    );
    await File(stagedPath).writeAsBytes(bytes, flush: true);
    return StagedRoutineImage(
      path: stagedPath,
      originalFileName: path.basename(file.name),
      mimeType: keepPng ? 'image/png' : 'image/jpeg',
      byteSize: bytes.length,
      width: width,
      height: height,
      sha256: sha256.convert(bytes).toString(),
    );
  }

  Future<String> moveToPermanent({
    required StagedRoutineImage image,
    required String routineId,
    required String attachmentId,
  }) async {
    final root = await _attachmentRoot();
    final extension = image.mimeType == 'image/png' ? 'png' : 'jpg';
    final relative = path.join(routineId, '$attachmentId.$extension');
    final target = File(path.join(root.path, relative));
    await target.parent.create(recursive: true);
    await File(image.path).copy(target.path);
    return relative;
  }

  Future<File?> resolve(String? relativePath) async {
    if (relativePath == null || path.isAbsolute(relativePath)) return null;
    final root = await _attachmentRoot();
    final rootPath = path.normalize(root.path) + path.separator;
    final targetPath = path.normalize(path.join(rootPath, relativePath));
    if (!targetPath.startsWith(rootPath)) return null;
    final file = File(targetPath);
    return await file.exists() ? file : null;
  }

  Future<void> deleteRelative(String? relativePath) async {
    final file = await resolve(relativePath);
    if (file != null) await file.delete();
  }

  Future<void> deleteStaged(String stagedPath) async {
    final temp = await getTemporaryDirectory();
    final root = path.join(temp.path, stagingFolder) + path.separator;
    if (!path.normalize(stagedPath).startsWith(root)) return;
    final file = File(stagedPath);
    if (await file.exists()) await file.delete();
  }

  Future<void> cleanStaging({String? routineId}) async {
    final temp = await getTemporaryDirectory();
    final root = Directory(path.join(temp.path, stagingFolder));
    if (!await root.exists()) return;
    final target = routineId == null
        ? root
        : Directory(path.join(root.path, routineId));
    if (await target.exists()) await target.delete(recursive: true);
  }

  Future<List<String>> findOrphans(Set<String> referencedRelativePaths) async {
    final root = await _attachmentRoot();
    if (!await root.exists()) return const [];
    final orphans = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relative = path.relative(entity.path, from: root.path);
        if (!referencedRelativePaths.contains(relative)) orphans.add(relative);
      }
    }
    return orphans;
  }

  Future<void> deleteOrphanFiles(Set<String> referencedRelativePaths) async {
    for (final orphan in await findOrphans(referencedRelativePaths)) {
      await deleteRelative(orphan);
    }
  }

  Future<Directory> _attachmentRoot() async {
    final support = await getApplicationSupportDirectory();
    return Directory(path.join(support.path, attachmentFolder));
  }
}

class RoutineAttachmentTooLargeException implements Exception {
  const RoutineAttachmentTooLargeException();
}

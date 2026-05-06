import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/file_repository.dart';
import '../domain/file_attachment.dart';

final fileRepositoryProvider = FutureProvider<FileRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return FileRepository(dio);
});

/// reference 별 첨부 파일.
typedef FileRefKey = ({String referenceType, int referenceRowId});

final filesByReferenceProvider =
    FutureProvider.family<List<FileAttachment>, FileRefKey>((ref, key) async {
  final repo = await ref.watch(fileRepositoryProvider.future);
  return repo.listByReference(
      referenceType: key.referenceType, referenceRowId: key.referenceRowId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../../features/markup/data/repositories/markup_repository_impl.dart';
import '../../features/markup/domain/repositories/markup_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final markupRepositoryProvider = Provider<MarkupRepository>((ref) {
  return MarkupRepositoryImpl();
});

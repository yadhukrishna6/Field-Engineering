import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/offline_storage_manager.dart';
import '../../../../core/storage/storage_models.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/core_providers.dart';

class OfflineStorageState {
  final bool isLoading;
  final StorageUsage usage;
  final String? errorMessage;
  final List<FileSystemEntity> activeCategoryFiles;
  final StorageCategory selectedCategory;

  const OfflineStorageState({
    this.isLoading = false,
    this.usage = const StorageUsage(
      pdfsBytes: 0,
      thumbnailsBytes: 0,
      photosBytes: 0,
      attachmentsBytes: 0,
      reportsBytes: 0,
      databaseBytes: 0,
      totalUsedBytes: 0,
    ),
    this.errorMessage,
    this.activeCategoryFiles = const [],
    this.selectedCategory = StorageCategory.pdfs,
  });

  OfflineStorageState copyWith({
    bool? isLoading,
    StorageUsage? usage,
    String? errorMessage,
    List<FileSystemEntity>? activeCategoryFiles,
    StorageCategory? selectedCategory,
  }) {
    return OfflineStorageState(
      isLoading: isLoading ?? this.isLoading,
      usage: usage ?? this.usage,
      errorMessage: errorMessage,
      activeCategoryFiles: activeCategoryFiles ?? this.activeCategoryFiles,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class OfflineStorageNotifier extends StateNotifier<OfflineStorageState> {
  final OfflineStorageManager _storageManager;
  final AppDatabase _database;

  OfflineStorageNotifier(this._storageManager, this._database)
      : super(const OfflineStorageState()) {
    refreshUsage();
  }

  Future<void> refreshUsage() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dbBytes = await _database.getDatabaseSizeInBytes();
      final usage = await _storageManager.calculateStorageUsage(dbBytes);
      final files = await _storageManager.listCategoryFiles(state.selectedCategory);
      state = state.copyWith(
        isLoading: false,
        usage: usage,
        activeCategoryFiles: files,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to calculate storage usage: $e',
      );
    }
  }

  Future<void> selectCategory(StorageCategory category) async {
    state = state.copyWith(selectedCategory: category, isLoading: true);
    try {
      final files = await _storageManager.listCategoryFiles(category);
      state = state.copyWith(
        selectedCategory: category,
        activeCategoryFiles: files,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to list files: $e');
    }
  }

  Future<void> purgeCategory(StorageCategory category) async {
    state = state.copyWith(isLoading: true);
    try {
      await _storageManager.clearCategory(category);
      await refreshUsage();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to purge category: $e');
    }
  }
}

final offlineStorageNotifierProvider =
    StateNotifierProvider<OfflineStorageNotifier, OfflineStorageState>((ref) {
  final storageManager = ref.watch(storageManagerProvider);
  final database = ref.watch(databaseProvider);
  return OfflineStorageNotifier(storageManager, database);
});

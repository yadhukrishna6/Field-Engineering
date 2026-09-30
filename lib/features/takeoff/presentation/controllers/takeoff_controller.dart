import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/takeoff_item.dart';
import '../../domain/repositories/takeoff_repository.dart';
import '../../../drawings/domain/models/measurement.dart';
import '../../../../core/providers/core_providers.dart';

class TakeoffState {
  final List<TakeoffItem> items;
  final bool isLoading;
  final String? selectedProjectId;
  final String? selectedDrawingId;
  final TakeoffItemType? filterType;
  final String searchQuery;
  final String? error;

  const TakeoffState({
    this.items = const [],
    this.isLoading = false,
    this.selectedProjectId,
    this.selectedDrawingId,
    this.filterType,
    this.searchQuery = '',
    this.error,
  });

  TakeoffState copyWith({
    List<TakeoffItem>? items,
    bool? isLoading,
    String? selectedProjectId,
    String? selectedDrawingId,
    TakeoffItemType? filterType,
    bool clearFilterType = false,
    String? searchQuery,
    String? error,
  }) {
    return TakeoffState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      selectedDrawingId: selectedDrawingId ?? this.selectedDrawingId,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }

  // Calculated Aggregate Totals
  int get totalUniqueItems => items.length;

  double get totalQuantity => items.fold(0.0, (sum, i) => sum + i.quantity);

  double get totalWeightKg => items.fold(0.0, (sum, i) => sum + i.totalWeightKg);

  double get totalCost => items.fold(0.0, (sum, i) => sum + i.totalCost);

  Map<TakeoffItemType, int> get countByType {
    final map = <TakeoffItemType, int>{};
    for (final i in items) {
      map[i.itemType] = (map[i.itemType] ?? 0) + 1;
    }
    return map;
  }
}

class TakeoffController extends StateNotifier<TakeoffState> {
  final TakeoffRepository _repository;
  final _uuid = const Uuid();

  TakeoffController(this._repository) : super(const TakeoffState()) {
    loadItems();
  }

  Future<void> loadItems({String? projectId, String? drawingId}) async {
    state = state.copyWith(
      isLoading: true,
      selectedProjectId: projectId,
      selectedDrawingId: drawingId,
      error: null,
    );
    try {
      final list = await _repository.getTakeoffItems(
        projectId: projectId,
        drawingId: drawingId,
      );
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilterType(TakeoffItemType? type) {
    if (type == null) {
      state = state.copyWith(clearFilterType: true);
    } else {
      state = state.copyWith(filterType: type);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<TakeoffItem> addItem({
    required String projectId,
    String? drawingId,
    int pageNumber = 1,
    required TakeoffItemType itemType,
    required String itemName,
    String? specification,
    String? size,
    required double quantity,
    required String unit,
    double unitWeightKg = 0.0,
    double unitCost = 0.0,
    String? notes,
    String? linkedCountTag,
  }) async {
    final item = TakeoffItem(
      id: _uuid.v4(),
      projectId: projectId,
      drawingId: drawingId,
      pageNumber: pageNumber,
      itemType: itemType,
      itemName: itemName,
      specification: specification,
      size: size,
      quantity: quantity,
      unit: unit,
      unitWeightKg: unitWeightKg,
      unitCost: unitCost,
      notes: notes,
      linkedCountTag: linkedCountTag,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final saved = await _repository.saveTakeoffItem(item);
    state = state.copyWith(
      items: [saved, ...state.items.where((i) => i.id != saved.id)],
    );
    return saved;
  }

  Future<TakeoffItem> updateItem(TakeoffItem item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    final saved = await _repository.saveTakeoffItem(updated);
    state = state.copyWith(
      items: state.items.map((i) => i.id == saved.id ? saved : i).toList(),
    );
    return saved;
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteTakeoffItem(id);
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
  }

  Future<void> importCountsFromDrawing({
    required String projectId,
    required String drawingId,
    required int pageNumber,
    required List<Measurement> countMeasurements,
  }) async {
    // Group counts by label
    final Map<String, int> grouped = {};
    for (final m in countMeasurements) {
      final label = m.countLabel.isEmpty ? 'Component' : m.countLabel;
      grouped[label] = (grouped[label] ?? 0) + 1;
    }

    for (final entry in grouped.entries) {
      final label = entry.key;
      final count = entry.value.toDouble();

      // Guess type from name
      TakeoffItemType type = TakeoffItemType.custom;
      final lower = label.toLowerCase();
      if (lower.contains('pipe')) type = TakeoffItemType.pipe;
      if (lower.contains('valve')) type = TakeoffItemType.valve;
      if (lower.contains('flange')) type = TakeoffItemType.flange;
      if (lower.contains('elbow')) type = TakeoffItemType.elbow;
      if (lower.contains('tee')) type = TakeoffItemType.tee;
      if (lower.contains('reducer')) type = TakeoffItemType.reducer;
      if (lower.contains('support')) type = TakeoffItemType.support;
      if (lower.contains('pump') || lower.contains('vessel') || lower.contains('tank')) {
        type = TakeoffItemType.equipment;
      }

      await addItem(
        projectId: projectId,
        drawingId: drawingId,
        pageNumber: pageNumber,
        itemType: type,
        itemName: label,
        quantity: count,
        unit: 'pcs',
        notes: 'Imported from Drawing Sheet $pageNumber Count Tool',
        linkedCountTag: label,
      );
    }
  }
}

final takeoffControllerProvider =
    StateNotifierProvider<TakeoffController, TakeoffState>((ref) {
  final repo = ref.watch(takeoffRepositoryProvider);
  return TakeoffController(repo);
});

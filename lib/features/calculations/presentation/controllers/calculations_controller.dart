import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/saved_calculation.dart';
import '../../domain/repositories/saved_calculations_repository.dart';
import '../../../../core/providers/core_providers.dart';

class CalculationsState {
  final List<SavedCalculation> savedCalculations;
  final bool isLoading;
  final String? filterType;
  final String? error;

  const CalculationsState({
    this.savedCalculations = const [],
    this.isLoading = false,
    this.filterType,
    this.error,
  });

  CalculationsState copyWith({
    List<SavedCalculation>? savedCalculations,
    bool? isLoading,
    String? filterType,
    String? error,
  }) {
    return CalculationsState(
      savedCalculations: savedCalculations ?? this.savedCalculations,
      isLoading: isLoading ?? this.isLoading,
      filterType: filterType ?? this.filterType,
      error: error,
    );
  }
}

class CalculationsController extends StateNotifier<CalculationsState> {
  final SavedCalculationsRepository _repository;
  final _uuid = const Uuid();

  CalculationsController(this._repository) : super(const CalculationsState()) {
    loadSaved();
  }

  Future<void> loadSaved({String? calcType}) async {
    state = state.copyWith(isLoading: true, filterType: calcType, error: null);
    try {
      final list = await _repository.getSavedCalculations(calcType: calcType);
      state = state.copyWith(savedCalculations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<SavedCalculation> saveCalculation({
    required String calcType,
    required String title,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> results,
    String? engineerNotes,
    String? projectId,
    String? drawingId,
  }) async {
    final calc = SavedCalculation(
      id: _uuid.v4(),
      projectId: projectId,
      drawingId: drawingId,
      calcType: calcType,
      title: title,
      inputs: inputs,
      results: results,
      engineerNotes: engineerNotes,
      createdAt: DateTime.now(),
    );

    final saved = await _repository.saveCalculation(calc);
    state = state.copyWith(
      savedCalculations: [saved, ...state.savedCalculations.where((c) => c.id != saved.id)],
    );
    return saved;
  }

  Future<void> deleteCalculation(String id) async {
    await _repository.deleteCalculation(id);
    state = state.copyWith(
      savedCalculations: state.savedCalculations.where((c) => c.id != id).toList(),
    );
  }
}

final calculationsControllerProvider =
    StateNotifierProvider<CalculationsController, CalculationsState>((ref) {
  final repo = ref.watch(savedCalculationsRepositoryProvider);
  return CalculationsController(repo);
});

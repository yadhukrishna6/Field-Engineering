import '../../domain/models/saved_calculation.dart';
import '../../domain/repositories/saved_calculations_repository.dart';
import '../datasources/saved_calculations_local_datasource.dart';

class SavedCalculationsRepositoryImpl implements SavedCalculationsRepository {
  final SavedCalculationsLocalDataSource localDataSource;

  SavedCalculationsRepositoryImpl({required this.localDataSource});

  @override
  Future<List<SavedCalculation>> getSavedCalculations({String? calcType}) {
    return localDataSource.getSavedCalculations(calcType: calcType);
  }

  @override
  Future<SavedCalculation> saveCalculation(SavedCalculation calculation) {
    return localDataSource.saveCalculation(calculation);
  }

  @override
  Future<bool> deleteCalculation(String id) {
    return localDataSource.deleteCalculation(id);
  }
}

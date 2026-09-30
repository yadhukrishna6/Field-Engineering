import '../models/saved_calculation.dart';

abstract class SavedCalculationsRepository {
  Future<List<SavedCalculation>> getSavedCalculations({String? calcType});
  Future<SavedCalculation> saveCalculation(SavedCalculation calculation);
  Future<bool> deleteCalculation(String id);
}

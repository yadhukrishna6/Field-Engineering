import '../../domain/models/measurement.dart';
import '../../domain/models/drawing_calibration.dart';
import '../../domain/repositories/measurements_repository.dart';
import '../datasources/measurements_local_datasource.dart';

class MeasurementsRepositoryImpl implements MeasurementsRepository {
  final MeasurementsLocalDataSource localDataSource;

  MeasurementsRepositoryImpl({required this.localDataSource});

  @override
  Future<DrawingCalibration?> getCalibration(String drawingId, {int pageNumber = 1}) {
    return localDataSource.getCalibration(drawingId, pageNumber: pageNumber);
  }

  @override
  Future<DrawingCalibration> saveCalibration(DrawingCalibration calibration) {
    return localDataSource.saveCalibration(calibration);
  }

  @override
  Future<bool> deleteCalibration(String drawingId, {int? pageNumber}) {
    return localDataSource.deleteCalibration(drawingId, pageNumber: pageNumber);
  }

  @override
  Future<List<Measurement>> getMeasurementsForDrawing(String drawingId, {int? pageNumber}) {
    return localDataSource.getMeasurementsForDrawing(drawingId, pageNumber: pageNumber);
  }

  @override
  Future<Measurement> saveMeasurement(Measurement measurement) {
    return localDataSource.saveMeasurement(measurement);
  }

  @override
  Future<List<Measurement>> saveMeasurementsBatch(List<Measurement> measurements) {
    return localDataSource.saveMeasurementsBatch(measurements);
  }

  @override
  Future<bool> deleteMeasurement(String id) {
    return localDataSource.deleteMeasurement(id);
  }

  @override
  Future<bool> deleteMeasurementsForDrawing(String drawingId, {int? pageNumber}) {
    return localDataSource.deleteMeasurementsForDrawing(drawingId, pageNumber: pageNumber);
  }
}

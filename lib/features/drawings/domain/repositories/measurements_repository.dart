import '../models/measurement.dart';
import '../models/drawing_calibration.dart';

abstract class MeasurementsRepository {
  Future<DrawingCalibration?> getCalibration(String drawingId, {int pageNumber = 1});
  Future<DrawingCalibration> saveCalibration(DrawingCalibration calibration);
  Future<bool> deleteCalibration(String drawingId, {int? pageNumber});

  Future<List<Measurement>> getMeasurementsForDrawing(String drawingId, {int? pageNumber});
  Future<Measurement> saveMeasurement(Measurement measurement);
  Future<List<Measurement>> saveMeasurementsBatch(List<Measurement> measurements);
  Future<bool> deleteMeasurement(String id);
  Future<bool> deleteMeasurementsForDrawing(String drawingId, {int? pageNumber});
}

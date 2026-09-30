import '../models/photo_attachment.dart';

abstract class PhotosRepository {
  Future<void> savePhoto(PhotoAttachment photo);
  Future<void> deletePhoto(String photoId);
  Future<List<PhotoAttachment>> getPhotosByIssue(String issueId);
  Future<List<PhotoAttachment>> getPhotosByInspection(String inspectionId);
  Future<List<PhotoAttachment>> getPhotosByEquipment(String equipmentId);
  Future<List<PhotoAttachment>> getPhotosByDrawing(String drawingId, {int? pageNumber});
  Future<List<PhotoAttachment>> getAllPhotos();
}

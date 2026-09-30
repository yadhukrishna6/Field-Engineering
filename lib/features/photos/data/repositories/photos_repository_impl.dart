import '../../domain/models/photo_attachment.dart';
import '../../domain/repositories/photos_repository.dart';
import '../datasources/photos_local_datasource.dart';

class PhotosRepositoryImpl implements PhotosRepository {
  final PhotosLocalDataSource _localDataSource;

  PhotosRepositoryImpl({required PhotosLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<void> savePhoto(PhotoAttachment photo) => _localDataSource.insertPhoto(photo);

  @override
  Future<void> deletePhoto(String photoId) => _localDataSource.deletePhoto(photoId);

  @override
  Future<List<PhotoAttachment>> getPhotosByIssue(String issueId) =>
      _localDataSource.getPhotosByIssue(issueId);

  @override
  Future<List<PhotoAttachment>> getPhotosByInspection(String inspectionId) =>
      _localDataSource.getPhotosByInspection(inspectionId);

  @override
  Future<List<PhotoAttachment>> getPhotosByEquipment(String equipmentId) =>
      _localDataSource.getPhotosByEquipment(equipmentId);

  @override
  Future<List<PhotoAttachment>> getPhotosByDrawing(String drawingId, {int? pageNumber}) =>
      _localDataSource.getPhotosByDrawing(drawingId, pageNumber: pageNumber);

  @override
  Future<List<PhotoAttachment>> getAllPhotos() => _localDataSource.getAllPhotos();
}

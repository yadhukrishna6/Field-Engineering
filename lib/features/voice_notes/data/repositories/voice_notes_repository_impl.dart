import '../../domain/models/voice_note.dart';
import '../../domain/repositories/voice_notes_repository.dart';
import '../datasources/voice_notes_local_datasource.dart';

class VoiceNotesRepositoryImpl implements VoiceNotesRepository {
  final VoiceNotesLocalDataSource _localDataSource;

  VoiceNotesRepositoryImpl({required VoiceNotesLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<void> saveVoiceNote(VoiceNote voiceNote) => _localDataSource.insertVoiceNote(voiceNote);

  @override
  Future<void> deleteVoiceNote(String id) => _localDataSource.deleteVoiceNote(id);

  @override
  Future<List<VoiceNote>> getVoiceNotesByIssue(String issueId) =>
      _localDataSource.getVoiceNotesByIssue(issueId);

  @override
  Future<List<VoiceNote>> getVoiceNotesByInspection(String inspectionId) =>
      _localDataSource.getVoiceNotesByInspection(inspectionId);

  @override
  Future<List<VoiceNote>> getVoiceNotesByDrawing(String drawingId, {int? pageNumber}) =>
      _localDataSource.getVoiceNotesByDrawing(drawingId, pageNumber: pageNumber);

  @override
  Future<List<VoiceNote>> getAllVoiceNotes() => _localDataSource.getAllVoiceNotes();
}

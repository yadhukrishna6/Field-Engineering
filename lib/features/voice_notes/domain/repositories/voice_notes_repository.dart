import '../models/voice_note.dart';

abstract class VoiceNotesRepository {
  Future<void> saveVoiceNote(VoiceNote voiceNote);
  Future<void> deleteVoiceNote(String id);
  Future<List<VoiceNote>> getVoiceNotesByIssue(String issueId);
  Future<List<VoiceNote>> getVoiceNotesByInspection(String inspectionId);
  Future<List<VoiceNote>> getVoiceNotesByDrawing(String drawingId, {int? pageNumber});
  Future<List<VoiceNote>> getAllVoiceNotes();
}

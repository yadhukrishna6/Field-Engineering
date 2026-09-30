import '../models/issue.dart';

abstract class IssuesRepository {
  Future<void> saveIssue(Issue issue);
  Future<void> updateIssue(Issue issue);
  Future<void> deleteIssue(String issueId);
  Future<List<Issue>> getIssuesByProject(String projectId);
  Future<List<Issue>> getIssuesByDrawing(String drawingId, {int? pageNumber});
  Future<List<Issue>> getAllIssues();
  Future<Issue?> getIssueById(String id);
}

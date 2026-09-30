import '../../domain/models/issue.dart';
import '../../domain/repositories/issues_repository.dart';
import '../datasources/issues_local_datasource.dart';

class IssuesRepositoryImpl implements IssuesRepository {
  final IssuesLocalDataSource _localDataSource;

  IssuesRepositoryImpl({required IssuesLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<void> saveIssue(Issue issue) => _localDataSource.insertIssue(issue);

  @override
  Future<void> updateIssue(Issue issue) => _localDataSource.updateIssue(issue);

  @override
  Future<void> deleteIssue(String issueId) => _localDataSource.deleteIssue(issueId);

  @override
  Future<List<Issue>> getIssuesByProject(String projectId) => _localDataSource.getIssuesByProject(projectId);

  @override
  Future<List<Issue>> getIssuesByDrawing(String drawingId, {int? pageNumber}) =>
      _localDataSource.getIssuesByDrawing(drawingId, pageNumber: pageNumber);

  @override
  Future<List<Issue>> getAllIssues() => _localDataSource.getAllIssues();

  @override
  Future<Issue?> getIssueById(String id) => _localDataSource.getIssueById(id);
}

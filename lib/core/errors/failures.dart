abstract class Failure {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => '$runtimeType: $message';
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.error, super.stackTrace]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.error, super.stackTrace]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.error, super.stackTrace]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.error, super.stackTrace]);
}

class PdfProcessingFailure extends Failure {
  const PdfProcessingFailure(super.message, [super.error, super.stackTrace]);
}

class OfflineSyncFailure extends Failure {
  const OfflineSyncFailure(super.message, [super.error, super.stackTrace]);
}

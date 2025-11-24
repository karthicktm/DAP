class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic response;

  ApiException(this.message, {this.statusCode, this.response});

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}

class AudioException implements Exception {
  final String message;
  final String? code;

  AudioException(this.message, {this.code});

  @override
  String toString() {
    return 'AudioException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class StorageException implements Exception {
  final String message;
  final String? operation;

  StorageException(this.message, {this.operation});

  @override
  String toString() {
    return 'StorageException: $message${operation != null ? ' (Operation: $operation)' : ''}';
  }
}

class ValidationException implements Exception {
  final String message;
  final String? field;

  ValidationException(this.message, {this.field});

  @override
  String toString() {
    return 'ValidationException: $message${field != null ? ' (Field: $field)' : ''}';
  }
}
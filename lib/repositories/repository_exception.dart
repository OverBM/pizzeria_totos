/// Error de dominio con un mensaje legible para la vista.
class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

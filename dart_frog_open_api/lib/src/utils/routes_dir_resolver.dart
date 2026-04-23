import 'dart:io';

/// Resolves the `routes/` directory path relative to a known base.
///
/// Dart Frog runs the server process from the service root, so
/// `Directory('routes')` (relative to CWD) works correctly at runtime.
/// This helper makes that convention explicit and testable.
///
/// Usage in a route file:
/// ```dart
/// routesDir: RoutesDirResolver.fromCwd()
/// ```
class RoutesDirResolver {
  const RoutesDirResolver._();

  /// Returns a [Directory] for [folder] resolved relative to [base].
  ///
  /// If [folder] is already an absolute path, it is returned as-is.
  static Directory resolveFrom(Directory base, String folder) {
    if (folder.startsWith('/') || folder.startsWith(r'\')) {
      return Directory(folder);
    }
    return Directory('${base.path}/$folder');
  }

  /// Returns a [Directory] for [folder] relative to the current
  /// working directory ([Directory.current]).
  ///
  /// This is equivalent to `Directory(folder)` but makes the intention
  /// explicit and allows easy swapping in tests.
  static Directory fromCwd({String folder = 'routes'}) {
    return resolveFrom(Directory.current, folder);
  }
}

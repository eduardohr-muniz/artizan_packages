/// In-memory cache for the generated OpenAPI spec with a configurable TTL.
///
/// Prevents CPU/IO spikes by reusing the previously built spec for [ttl]
/// duration, acting as a basic DoS mitigation for documentation endpoints.
///
/// When [ttl] is [Duration.zero], [get] always returns `null` (caching
/// effectively disabled).
///
/// ```dart
/// final cache = SpecCache(ttl: Duration(minutes: 5));
///
/// final cached = cache.get();
/// if (cached != null) return cached;
///
/// final spec = buildSpec();
/// cache.set(spec);
/// return spec;
/// ```
class SpecCache {
  SpecCache({required this.ttl});

  /// How long a cached entry is considered valid.
  final Duration ttl;

  Map<String, dynamic>? _spec;
  DateTime? _cachedAt;

  /// Returns the cached spec if it exists and has not expired; otherwise `null`.
  Map<String, dynamic>? get() {
    if (_spec == null || _cachedAt == null) return null;
    if (ttl == Duration.zero) return null;
    if (DateTime.now().difference(_cachedAt!) >= ttl) {
      _spec = null;
      _cachedAt = null;
      return null;
    }
    return _spec;
  }

  /// Stores [spec] in the cache and resets the TTL timer.
  void set(Map<String, dynamic> spec) {
    _spec = spec;
    _cachedAt = DateTime.now();
  }

  /// Clears the cached entry immediately (e.g. on hot-reload or config change).
  void invalidate() {
    _spec = null;
    _cachedAt = null;
  }
}

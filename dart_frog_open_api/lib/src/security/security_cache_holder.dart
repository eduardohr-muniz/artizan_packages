import 'spec_cache.dart';

/// Holds the [SpecCache] singleton used by [DartFrogOpenApi].
///
/// Exists as a separate class so that [DartFrogOpenApi.reset] can clear
/// and recreate the cache without making [SpecCache] a global.
class SecurityCacheHolder {
  SpecCache _cache = SpecCache(ttl: const Duration(minutes: 5));

  /// The active cache instance.
  SpecCache get cache => _cache;

  /// Recreates the cache with the given [ttl]. Called on [DartFrogOpenApi.initialize].
  void reset(Duration ttl) {
    _cache = SpecCache(ttl: ttl);
  }

  /// Clears the cached entry. Called on [DartFrogOpenApi.reset].
  void invalidate() => _cache.invalidate();
}

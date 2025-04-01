class CacheStatsTracker {
  int cacheHits = 0;
  int cacheMisses = 0;
  int cacheExpired = 0;
  int networkRequests = 0;
  int totalStorage = 0;

  void trackCacheHit() {
    cacheHits++;
  }

  void trackCacheMiss() {
    cacheMisses++;
  }

  void trackCacheExpired() {
    cacheExpired++;
  }

  void trackNetworkRequest() {
    networkRequests++;
  }

  void updateTotalStorage(int bytes) {
    totalStorage = bytes;
  }

  void reset() {
    cacheHits = 0;
    cacheMisses = 0;
    cacheExpired = 0;
    networkRequests = 0;
  }

  double get hitRatio => totalRequests > 0 ? cacheHits / totalRequests : 0;
  int get totalRequests => cacheHits + cacheMisses + cacheExpired;
}

final class PaginationHelper {
  PaginationHelper._();

  static bool hasCachedPage({
    required int page,
    required int pageSize,
    required int totalCount,
    required int totalItems,
  }) {
    final startIndex = (page - 1) * pageSize;

    final requiredCount = (totalCount > 0 && page * pageSize > totalCount)
        ? totalCount
        : page * pageSize;

    return totalItems >= requiredCount ||
        (totalCount > 0 && totalItems >= totalCount && totalItems > startIndex);
  }
}

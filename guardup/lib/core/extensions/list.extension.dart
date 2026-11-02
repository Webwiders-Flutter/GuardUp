import '/core/constants/app_constants.dart';

typedef ReorderResult<T> = ({List<T> items, T reorderedItem});

extension ListReorderExtension<T> on List<T> {
  ReorderResult<T>? reorderWithSortOrder({
    required int oldIndex,
    required int newIndex,
    required int Function(T item) getSortOrder,
    required T Function(T item, int newSortOrder) copyWithSortOrder,
    int sortOrderGap = AppConstants.sortOrderGap,
  }) {
    if (isEmpty || oldIndex < 0 || oldIndex >= length) {
      return null;
    }

    final items = [...this];

    final draggedItem = items.removeAt(oldIndex);

    final targetIndex = newIndex.clamp(0, items.length);

    if (oldIndex == targetIndex) {
      return null;
    }

    final int newSortOrder;

    if (targetIndex == 0) {
      final nextSortOrder = getSortOrder(items.first);
      newSortOrder = nextSortOrder - sortOrderGap;
    } else if (targetIndex == items.length) {
      final previousSortOrder = getSortOrder(items.last);
      newSortOrder = previousSortOrder + sortOrderGap;
    } else {
      final previousSortOrder = getSortOrder(items[targetIndex - 1]);
      final nextSortOrder = getSortOrder(items[targetIndex]);

      newSortOrder = (previousSortOrder + nextSortOrder) ~/ 2;
    }

    final updatedItem = copyWithSortOrder(draggedItem, newSortOrder);

    items.insert(targetIndex, updatedItem);

    return (items: items, reorderedItem: updatedItem);
  }

  List<T> updateItem({required String id, required T item}) {
    final index = indexWhere((e) {
      return (e as dynamic).id == id;
    });
    if (index != -1) {
      final items = [...this];
      items[index] = item;
      return items;
    }
    return this;
  }
}

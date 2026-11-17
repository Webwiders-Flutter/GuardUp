class SelectableItem<V, D> {
  final V id;
  final D data;

  const SelectableItem({required this.id, required this.data});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SelectableItem && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}

/// Defines the shape of a [QuickContainer].
enum AppContainerShape {
  /// Standard rectangle. Use [QuickContainer.radius] or [QuickContainer.borderRadius] for rounded corners.
  rectangle,

  /// Perfect circle. Width and height should be equal.
  circle,

  /// Stadium / capsule shape — fully rounded ends.
  stadium,
}

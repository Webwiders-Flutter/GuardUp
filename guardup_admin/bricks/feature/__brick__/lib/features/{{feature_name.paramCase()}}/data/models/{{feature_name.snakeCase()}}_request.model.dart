import '/core/constants/api/json_keys.dart';

/// Request model representing payload for creating or updating a [{{feature_name.pascalCase()}}].
class {{feature_name.pascalCase()}}Request {
  final int? sortOrder;

  const {{feature_name.pascalCase()}}Request({
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (sortOrder != null) JsonKeys.sortOrder: sortOrder,
    };
  }
}

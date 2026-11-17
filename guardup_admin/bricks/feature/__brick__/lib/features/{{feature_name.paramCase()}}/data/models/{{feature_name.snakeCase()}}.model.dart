import '/core/constants/api/json_keys.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

part '{{feature_name.snakeCase()}}.model.freezed.dart';
part '{{feature_name.snakeCase()}}.model.g.dart';

@freezed
sealed class {{feature_name.pascalCase()}} with _${{feature_name.pascalCase()}} {
  const factory {{feature_name.pascalCase()}}({
    required String id,
    @Default(0) int sortOrder,
  }) = _{{feature_name.pascalCase()}};

  factory {{feature_name.pascalCase()}}.fromJson(Map<String, dynamic> json) =>
      _${{feature_name.pascalCase()}}FromJson(json);
}

export '{{feature_name.snakeCase()}}_request.model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '/shared/states/pagination.state.dart';
import '../data/models/{{feature_name.snakeCase()}}.model.dart';
import '../data/repositories/{{feature_name.snakeCase()}}.repository.dart';
import '../presentation/controllers/{{feature_name.snakeCase()}}.controller.dart';

final {{feature_name.camelCase()}}RepositoryProvider =
    Provider<{{feature_name.pascalCase()}}Repository>((ref) {
  return {{feature_name.pascalCase()}}Repository(ref.watch(supabaseClientProvider));
});

final {{feature_name.camelCase()}}ControllerProvider =
    AsyncNotifierProvider<{{feature_name.pascalCase()}}Controller,
        PaginationState<{{feature_name.pascalCase()}}>>(
      {{feature_name.pascalCase()}}Controller.new,
    );

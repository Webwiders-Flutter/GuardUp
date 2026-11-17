# Feature Scaffolding Brick

Enterprise feature scaffolding brick for Supplr Transport Hub Admin Flutter web application.

## Generated Artifacts

This brick generates a complete feature slice inside `lib/features/{{feature_name.paramCase()}}/`:
- `data/models/{{feature_name.snakeCase()}}.model.dart`: Freezed model with JSON serialization
- `data/repositories/{{feature_name.snakeCase()}}.repository.dart`: Concrete repository extending `BaseSupabaseRepository`
- `di/{{feature_name.snakeCase()}}.providers.dart`: Riverpod DI providers
- `presentation/controllers/{{feature_name.snakeCase()}}.controller.dart`: AsyncNotifier controller for pagination state
- `presentation/screens/{{feature_name.snakeCase()}}_management.screen.dart`: Enterprise Management Table Screen adhering to `rules.md` (Section 25)
- `presentation/screens/{{feature_name.snakeCase()}}.form.dart`: Enterprise Right-Side Slide-in Form Screen adhering to `rules.md` (Section 25)

## How to Usage

```bash
mason make feature --feature_name truck_type --entity_name "truck type" --table_name truckTypes
```

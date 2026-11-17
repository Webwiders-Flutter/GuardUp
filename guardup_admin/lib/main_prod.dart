import '/app/app.dart';
import '/bootstrap/bootstrap.dart';
import '/bootstrap/flavor.dart';

void main() async {
  await bootstrap(flavor: Flavor.prod, builder: () => App());
}

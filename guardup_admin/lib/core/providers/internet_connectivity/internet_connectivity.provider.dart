import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'internet_connectivity.controller.dart';
import '/core/services/connectivity/internet/internet_connectivity.service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityServiceImpl(),
);

final connectivityControllerProvider =
    NotifierProvider<ConnectivityController, bool>(ConnectivityController.new);

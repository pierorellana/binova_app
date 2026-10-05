import 'package:flutter/foundation.dart';

enum DemoNetworkMode {
  normal,
  slow,
  offline,
  serverError,
  timeout,
}

class DemoNetworkModeController extends ValueNotifier<DemoNetworkMode> {
  DemoNetworkModeController() : super(DemoNetworkMode.normal);
}

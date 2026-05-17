import 'package:flutter/foundation.dart';

class TestToolConfig {
  const TestToolConfig._();

  static const bool _enabledByDefine = bool.fromEnvironment(
    'ENABLE_TEST_TOOLS',
    defaultValue: false,
  );

  static const bool paymentSimulationEnabled = bool.fromEnvironment(
    'ENABLE_PAYMENT_SIMULATION',
    defaultValue: false,
  );

  static bool get enabled => kDebugMode || _enabledByDefine;
}

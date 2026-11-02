import 'dart:async';

import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  Timer? _debounce;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 100), notifyListeners);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}

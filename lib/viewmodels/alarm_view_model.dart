import 'package:flutter/foundation.dart';

class AlarmViewModel extends ChangeNotifier {
  bool _busy = false;
  bool get busy => _busy;

  Future<void> run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

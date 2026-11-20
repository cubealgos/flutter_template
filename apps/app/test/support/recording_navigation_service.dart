import 'package:mvc/mvc.dart';

/// A [NavigationService] that records where it was sent, for controller
/// tests that need no mock generation.
class RecordingNavigationService implements NavigationService {
  /// Locations passed to [go].
  final List<String> went = <String>[];

  /// Locations passed to [push].
  final List<String> pushed = <String>[];

  /// How many times [pop] was called.
  int pops = 0;

  @override
  void go(String location) => went.add(location);

  @override
  Future<T?> push<T extends Object?>(String location) async {
    pushed.add(location);

    return null;
  }

  @override
  void pop<T extends Object?>([T? result]) => pops++;

  @override
  bool canPop() => true;

  @override
  Future<T?> replace<T extends Object?>(String location) async => null;
}

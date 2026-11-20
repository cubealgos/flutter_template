import 'package:appwrite_tool/src/dry_run_ledger.dart';

class MemoryDryRunLedger implements DryRunLedger {
  final Set<String> shas = <String>{};

  @override
  bool has(String sha) => shas.contains(sha);

  @override
  void record(String sha) => shas.add(sha);
}

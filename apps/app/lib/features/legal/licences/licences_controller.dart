import 'dart:async';

import 'package:app/features/legal/licences/licence_group.dart';
import 'package:app/features/legal/licences/licences_model.dart';
import 'package:flutter/foundation.dart';
import 'package:mvc/mvc.dart';

/// Drives `LicencesView`: collects every OSS licence from
/// `LicenseRegistry.licenses` — never Material's `showLicensePage`, which
/// this template's no-Material rule forbids.
class LicencesController extends ViewController<LicencesModel> {
  /// Creates the controller. [licenses] defaults to
  /// `LicenseRegistry.licenses`; a test injects a fixed stream instead of
  /// depending on whatever licences happen to be globally registered.
  LicencesController(
    this._navigation,
    this._clipboard, {
    Stream<LicenseEntry>? licenses,
  }) : _licenses = licenses ?? LicenseRegistry.licenses,
       super(const LicencesModel());

  final NavigationService _navigation;
  final ClipboardService _clipboard;
  final Stream<LicenseEntry> _licenses;

  @override
  void init() {
    unawaited(_collect());
  }

  Future<void> _collect() async {
    // Grouped by package name, not one row per `LicenseEntry`: the same
    // package can be named by several entries (e.g. multiple bundled
    // licence files), which used to show as duplicate rows.
    final byPackage = <String, List<String>>{};
    await for (final entry in _licenses) {
      final text = entry.paragraphs
          .map((paragraph) => paragraph.text)
          .join('\n\n');
      for (final package in entry.packages) {
        (byPackage[package] ??= <String>[]).add(text);
      }
    }

    final collected =
        byPackage.entries
            .map(
              (entry) =>
                  LicenceGroup(packageName: entry.key, texts: entry.value),
            )
            .toList()
          ..sort((a, b) => a.packageName.compareTo(b.packageName));
    value = value.copyWith(entries: collected, loading: false);
  }

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }

  /// Copies [text] (one licence group's full text) to the system
  /// clipboard, via the injected [ClipboardService] — this template has no
  /// Material `SelectableText` to reach for instead.
  Future<void> copyLicenceText(String text) => _clipboard.copyText(text);
}

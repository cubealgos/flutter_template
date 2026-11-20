import 'package:app/features/legal/licences/licence_group.dart';
import 'package:mvc/mvc.dart';

/// `LicencesView`'s view model: the OSS licences collected so far from
/// `LicenseRegistry.licenses`, and whether collection has finished.
///
/// Not `freezed`: [entries] holds [LicenceGroup]s, which are deliberately
/// not `freezed` either (see that class's dartdoc) — a hand-written
/// `copyWith` is a few lines simpler here than the ceremony of a custom
/// equality override just to keep freezed happy about a list of
/// non-value-equal elements.
class LicencesModel implements ViewModel {
  /// Creates the model.
  const LicencesModel({
    this.entries = const <LicenceGroup>[],
    this.loading = true,
  });

  /// The licence groups collected so far, one per package name,
  /// alphabetically sorted.
  final List<LicenceGroup> entries;

  /// Whether `LicenseRegistry.licenses` is still emitting.
  final bool loading;

  /// Returns a copy with [entries] and/or [loading] replaced.
  LicencesModel copyWith({List<LicenceGroup>? entries, bool? loading}) =>
      LicencesModel(
        entries: entries ?? this.entries,
        loading: loading ?? this.loading,
      );
}

import 'package:app/features/legal/document/legal_document_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'legal_document_model.freezed.dart';

/// `LegalDocumentView`'s view model: just which document to render — the
/// view reads `AppConfig`'s placeholder legal facts directly (read-only
/// display data, not a service a controller test needs to mock; see
/// `LegalDocumentController`'s dartdoc).
@freezed
abstract class LegalDocumentModel
    with _$LegalDocumentModel
    implements ViewModel {
  /// Creates the model for [type].
  const factory LegalDocumentModel({required LegalDocumentType type}) =
      _LegalDocumentModel;
}

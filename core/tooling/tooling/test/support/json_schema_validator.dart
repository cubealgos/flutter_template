/// A minimal JSON Schema draft-07 validator — just enough of the spec to
/// validate CycloneDX's own vendored `bom-1.6.schema.json` against a
/// document this workspace generated: `type`, `required`, `properties` +
/// `additionalProperties` (boolean form only — the vendored schema never
/// uses the object form, checked by hand), `items` (schema or
/// tuple-array form, with `additionalItems`), `enum`, `pattern`,
/// `minLength`/`maxLength`, `uniqueItems`, `minimum`, `oneOf`, `anyOf` and
/// `$ref` — resolved both within one document and across `SchemaCtx`'s
/// own loaded documents (the CycloneDX schema `$ref`s out to
/// `spdx.schema.json`, and `jsf-0.82.schema.json` for a `signature` field
/// this workspace never emits).
///
/// Deliberately not a general-purpose JSON Schema engine — `if`/`then`,
/// `patternProperties`, `allOf` and the object form of
/// `additionalProperties` are all unsupported, but the vendored
/// `bom-1.6.schema.json` doesn't use any of those (checked by hand
/// against the file itself), and a general engine would be a lot
/// more code for constraints this document never needs validated. See
/// `sbom_document_test.dart`'s own doc comment for why this hand-rolled
/// validator exists at all rather than a pub.dev JSON-Schema package.
library;

/// A JSON object as decoded by `dart:convert`'s `jsonDecode` — every
/// schema node and every validated instance is shaped like this.
typedef JsonMap = Map<String, Object?>;

/// Every loaded schema document, keyed by filename, as the CycloneDX
/// schema's own cross-file `$ref`s name them (`spdx.schema.json`, …).
typedef SchemaDocs = Map<String, Object?>;

/// The loaded schema documents plus which one of them the current `$ref`
/// resolution is relative to — threaded through every recursive
/// validation call so each stays at 4 parameters or fewer (this repo's
/// own `number_of_parameters` threshold).
typedef SchemaCtx = ({SchemaDocs docs, String doc});

/// Validates [instance] against [rootDocument] (a key of [docs]) as a
/// whole schema. Returns every violation found, each a human-readable
/// `<path>: <problem>` string — empty means valid.
List<String> validateAgainstSchema({
  required Object? instance,
  required SchemaDocs docs,
  required String rootDocument,
}) {
  final ctx = (docs: docs, doc: rootDocument);

  return _validate(instance, docs[rootDocument], ctx, r'$');
}

List<String> _validate(
  Object? instance,
  Object? schema,
  SchemaCtx ctx,
  String path,
) {
  if (schema is! JsonMap) return const [];
  if (schema.containsKey(r'$ref')) {
    // The containsKey() check above already guarantees this isn't null.
    // ignore: solid_lints/avoid_non_null_assertion
    final ref = schema[r'$ref']! as String;
    final (resolved, resolvedCtx) = _resolveRef(ref, ctx);

    return _validate(instance, resolved, resolvedCtx, path);
  }

  return [
    ..._checkType(instance, schema, path),
    ..._checkEnum(instance, schema, path),
    ..._checkPattern(instance, schema, path),
    ..._checkStringLength(instance, schema, path),
    ..._checkMinimum(instance, schema, path),
    ..._checkRequired(instance, schema, path),
    ..._checkProperties(instance, schema, ctx, path),
    ..._checkItems(instance, schema, ctx, path),
    ..._checkUniqueItems(instance, schema, path),
    ..._checkOneOf(instance, schema, ctx, path),
    ..._checkAnyOf(instance, schema, ctx, path),
  ];
}

/// Whether [instance] matches JSON Schema's `type` string [type] — every
/// value `bom-1.6.schema.json` actually uses (`string`, `boolean`,
/// `array`, `object`, `integer`, `number`); an unrecognised `type` string
/// is treated as unconstrained rather than an error, matching how the
/// rest of this validator degrades for a keyword it doesn't implement.
bool _instanceMatchesType(Object? instance, String type) => switch (type) {
  'string' => instance is String,
  'boolean' => instance is bool,
  'array' => instance is List,
  'object' => instance is JsonMap,
  'integer' => instance is int,
  'number' => instance is num,
  _ => true,
};

List<String> _checkType(Object? instance, JsonMap schema, String path) {
  final type = schema['type'];
  if (type is! String) return const [];

  return _instanceMatchesType(instance, type)
      ? const []
      : ['$path: expected $type, got ${instance.runtimeType}.'];
}

List<String> _checkEnum(Object? instance, JsonMap schema, String path) {
  final values = schema['enum'];
  if (values is! List) return const [];

  return values.contains(instance)
      ? const []
      : ['$path: $instance not in enum $values.'];
}

List<String> _checkPattern(Object? instance, JsonMap schema, String path) {
  final pattern = schema['pattern'];
  if (pattern is! String || instance is! String) return const [];

  return RegExp(pattern).hasMatch(instance)
      ? const []
      : ["$path: '$instance' doesn't match pattern '$pattern'."];
}

List<String> _checkStringLength(Object? instance, JsonMap schema, String path) {
  if (instance is! String) return const [];
  final errors = <String>[];
  final minLength = schema['minLength'];
  if (minLength is int && instance.length < minLength) {
    errors.add('$path: shorter than minLength $minLength.');
  }
  final maxLength = schema['maxLength'];
  if (maxLength is int && instance.length > maxLength) {
    errors.add('$path: longer than maxLength $maxLength.');
  }

  return errors;
}

List<String> _checkMinimum(Object? instance, JsonMap schema, String path) {
  final minimum = schema['minimum'];
  if (minimum is! num || instance is! num) return const [];

  return instance >= minimum
      ? const []
      : ['$path: $instance is below minimum $minimum.'];
}

List<String> _checkRequired(Object? instance, JsonMap schema, String path) {
  final required = schema['required'];
  if (required is! List || instance is! JsonMap) return const [];

  return [
    for (final field in required)
      if (!instance.containsKey(field)) '$path: missing required "$field".',
  ];
}

List<String> _checkProperties(
  Object? instance,
  JsonMap schema,
  SchemaCtx ctx,
  String path,
) {
  if (instance is! JsonMap) return const [];
  final properties = schema['properties'];
  final knownProperties = properties is JsonMap
      ? properties
      : const <String, Object?>{};
  final additionalAllowed = schema['additionalProperties'] != false;

  final errors = <String>[];
  for (final key in instance.keys) {
    final propertySchema = knownProperties[key];
    if (propertySchema != null) {
      errors.addAll(
        _validate(instance[key], propertySchema, ctx, '$path.$key'),
      );
    } else if (!additionalAllowed) {
      errors.add('$path: unexpected property "$key".');
    }
  }

  return errors;
}

List<String> _checkItems(
  Object? instance,
  JsonMap schema,
  SchemaCtx ctx,
  String path,
) {
  if (instance is! List) return const [];
  final items = schema['items'];
  if (items is JsonMap) {
    return [
      for (var i = 0; i < instance.length; i++)
        ..._validate(instance[i], items, ctx, '$path[$i]'),
    ];
  }
  if (items is List) {
    return _checkTupleItems(instance, items, ctx, path);
  }

  return const [];
}

List<String> _checkTupleItems(
  List<Object?> instance,
  List<Object?> itemSchemas,
  SchemaCtx ctx,
  String path,
) {
  final errors = <String>[];
  for (var i = 0; i < instance.length; i++) {
    if (i >= itemSchemas.length) {
      errors.add('$path[$i]: no tuple schema for extra item.');
      continue;
    }
    errors.addAll(_validate(instance[i], itemSchemas[i], ctx, '$path[$i]'));
  }

  return errors;
}

List<String> _checkUniqueItems(Object? instance, JsonMap schema, String path) {
  if (schema['uniqueItems'] != true || instance is! List) return const [];
  final seen = <String>{};
  for (final item in instance) {
    if (!seen.add(item.toString())) {
      return ['$path: duplicate item $item (uniqueItems).'];
    }
  }

  return const [];
}

List<String> _checkOneOf(
  Object? instance,
  JsonMap schema,
  SchemaCtx ctx,
  String path,
) {
  final options = schema['oneOf'];
  if (options is! List) return const [];
  final matchCount = options
      .where((option) => _validate(instance, option, ctx, path).isEmpty)
      .length;

  return matchCount == 1
      ? const []
      : ['$path: matched $matchCount of oneOf ${options.length} schemas.'];
}

List<String> _checkAnyOf(
  Object? instance,
  JsonMap schema,
  SchemaCtx ctx,
  String path,
) {
  final options = schema['anyOf'];
  if (options is! List) return const [];
  final anyMatch = options.any(
    (option) => _validate(instance, option, ctx, path).isEmpty,
  );

  return anyMatch ? const [] : ['$path: matched none of anyOf schemas.'];
}

(Object?, SchemaCtx) _resolveRef(String ref, SchemaCtx ctx) {
  final hashIndex = ref.indexOf('#');
  final filePart = hashIndex < 0 ? ref : ref.substring(0, hashIndex);
  final pointer = hashIndex < 0 ? '' : ref.substring(hashIndex + 1);
  final targetDoc = filePart.isEmpty ? ctx.doc : filePart;
  final resolvedCtx = (docs: ctx.docs, doc: targetDoc);
  final root = ctx.docs[targetDoc];
  if (root == null) {
    throw StateError('json_schema_validator: unknown \$ref document $ref.');
  }

  return (_lookupPointer(root, pointer), resolvedCtx);
}

Object? _lookupPointer(Object? doc, String pointer) {
  if (pointer.isEmpty || pointer == '/') return doc;
  var node = doc;
  for (final rawToken in pointer.split('/').skip(1)) {
    final token = rawToken.replaceAll('~1', '/').replaceAll('~0', '~');
    node = node is JsonMap ? node[token] : null;
  }

  return node;
}

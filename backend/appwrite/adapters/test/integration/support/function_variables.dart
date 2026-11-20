import 'package:dart_appwrite/dart_appwrite.dart' as server;

/// Removes the variable [key] of the Function [functionId], if it has one.
Future<void> deleteFunctionVariable(
  server.Client client,
  String functionId,
  String key,
) async {
  final functions = server.Functions(client);
  final all = (await functions.listVariables(functionId: functionId)).variables;
  await Future.wait(
    all
        .where((variable) => variable.key == key)
        .map(
          (variable) => functions.deleteVariable(
            functionId: functionId,
            variableId: variable.$id,
          ),
        ),
  );
}

/// Sets the variable [key] of [functionId] to [value], replacing any old one.
// The client, the Function, the key, the value and the flag are five
// independent inputs; a parameter object would only rename them.
// ignore: solid_lints/number_of_parameters
Future<void> setFunctionVariable(
  server.Client client,
  String functionId,
  String key,
  String value, {
  bool secret = false,
}) async {
  await deleteFunctionVariable(client, functionId, key);
  await server.Functions(client).createVariable(
    functionId: functionId,
    variableId: server.ID.unique(),
    key: key,
    value: value,
    secret: secret,
  );
}

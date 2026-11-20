import 'package:appwrite_tool/src/backend_env.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// Builds a [Client] configured against [env].
Client buildClient(BackendEnv env) => Client()
    .setEndpoint(env.endpoint)
    .setProject(env.projectId)
    .setKey(env.apiKey);

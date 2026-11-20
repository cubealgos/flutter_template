// A throwaway SMTP server for tests: speaks just enough of the protocol for
// `package:mailer` and records what it was sent, so a test sees the real
// wire output, headers included.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/prefer_match_file_name

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A fake SMTP server on a loopback port.
class FakeSmtpServer {
  FakeSmtpServer._(this._server, this.rcptReply) {
    _server.listen(_serve);
  }

  final ServerSocket _server;
  final Set<Socket> _sockets = <Socket>{};

  /// How many expected connection errors (client hung up) were swallowed.
  int swallowedErrors = 0;

  /// The answer to `RCPT TO`.
  final String rcptReply;

  /// Every message body received (headers and body, as sent).
  final List<String> messages = <String>[];

  /// The port to connect to.
  int get port => _server.port;

  /// Starts a server; [rcptReply] is its answer to `RCPT TO` (use
  /// `550 no such user` or `450 try later` to simulate a refusal).
  static Future<FakeSmtpServer> start({String rcptReply = '250 ok'}) async =>
      FakeSmtpServer._(
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
        rcptReply,
      );

  void _swallow([Object? _]) => swallowedErrors++;

  /// Stops listening and tears down every open connection, so nothing is
  /// still being written when the test completes.
  Future<void> close() async {
    await _server.close();
    for (final socket in _sockets.toList()) {
      socket.destroy();
    }
    _sockets.clear();
  }

  void _serve(Socket socket) {
    _sockets.add(socket);
    // A client that hangs up right after a rejection leaves our reply
    // unwritable (EPIPE / reset). That is expected, not a failure: swallow it
    // here so it cannot surface as an uncaught error after the test ended.
    unawaited(
      socket.done
          .then<void>(_swallow, onError: _swallow)
          .whenComplete(() => _sockets.remove(socket)),
    );
    socket.write('220 localhost ESMTP\r\n');
    final data = StringBuffer();
    var inData = false;
    utf8.decoder
        .bind(socket)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (inData) {
              if (line == '.') {
                inData = false;
                messages.add(data.toString());
                data.clear();
                socket.write('250 queued\r\n');
              } else {
                data.writeln(line);
              }

              return;
            }
            final command = line.toUpperCase();
            if (command.startsWith('EHLO')) {
              socket.write('250 localhost\r\n');
            } else if (command.startsWith('RCPT')) {
              socket.write('$rcptReply\r\n');
            } else if (command.startsWith('DATA')) {
              inData = true;
              socket.write('354 go on\r\n');
            } else if (command.startsWith('QUIT')) {
              socket.write('221 bye\r\n');
              unawaited(socket.close().catchError(_swallow));
            } else {
              socket.write('250 ok\r\n');
            }
          },
          onError: _swallow,
          cancelOnError: true,
        );
  }
}

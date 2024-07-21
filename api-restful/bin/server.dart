// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as DartImage;
import 'package:cli/TfLiteFaceRecognition.dart';
import 'package:cli/rootBundle.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

Future<void> main() async {
  print("Server root dir: ${await rootBundle.rootDir()}");
  // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
  // https://cloud.google.com/run/docs/reference/container-contract#port
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  final cascade = Cascade()
      // First, serve files from the 'public' directory
      .add(_staticHandler)
      // If a corresponding file is not found, send requests to a `Router`
      .add(_router.call);

  // See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
  final server = await shelf_io.serve(
    // See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
    logRequests()
        // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
        .addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  print('Serving at http://${server.address.host}:${server.port}');

  // Used for tracking uptime of the demo server.
  _watch.start();
}

//
// Serve files from the file system.
final _staticHandler = shelf_static.createStaticHandler(
  'public', defaultDocument: 'index.html',
//    serveFilesOutsidePath: true
);

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..get('/helloworld', _helloWorldHandler)
  ..get(
    '/time',
    (request) => Response.ok(DateTime.now().toUtc().toIso8601String()),
  )
  ..get('/public', (request) {
    //this wrong not use because it belong to public folder
  })
  ..get('/public/info.json', (request) {
    //this wrong not use because it belong to public folder
  })
  ..get('/info.json', _infoHandler)
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>', _sumHandler)
  ..get('/tflite/test', (Request request) async {
    var xxx = await TfLiteFaceRecognition().TestChuNomDetect();
    return Response.ok(
      _jsonEncode({'data': xxx}),
      headers: {
        'content-type': 'application/json',
        'Cache-Control': 'public, max-age=604800, immutable',
      },
    );
  })
;

Response _helloWorldHandler(Request request) => Response.ok('Hello, World!');

String _jsonEncode(Object? data) =>
    const JsonEncoder.withIndent(' ').convert(data);

const _jsonHeaders = {
  'content-type': 'application/json',
};

Response _sumHandler(Request request, String a, String b) {
  final aNum = int.parse(a);
  final bNum = int.parse(b);
  return Response.ok(
    _jsonEncode({'a': aNum, 'b': bNum, 'sum': aNum + bNum}),
    headers: {
      ..._jsonHeaders,
      'Cache-Control': 'public, max-age=604800, immutable',
    },
  );
}

final _watch = Stopwatch();

int _requestCount = 0;

final _dartVersion = () {
  final version = Platform.version;
  return version.substring(0, version.indexOf(' '));
}();

Response _infoHandler(Request request) => Response(
      200,
      headers: {
        ..._jsonHeaders,
        'Cache-Control': 'no-store',
      },
      body: _jsonEncode(
        {
          'Dart version': _dartVersion,
          'uptime': _watch.elapsed.toString(),
          'requestCount': ++_requestCount,
        },
      ),
    );

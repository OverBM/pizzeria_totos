import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/core/app_info.dart';

void main() {
  test('AppInfo coincide con pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml debe declarar version');
    expect(match!.group(1), AppInfo.pubspecVersion);
    expect(AppInfo.version, '1.1.1');
    expect(AppInfo.build, 2);
  });

  test('la etiqueta visible es exactamente V1.1.1', () {
    expect(AppInfo.label, 'V1.1.1');
    expect(AppInfo.label, isNot(contains('2')));
    expect(AppInfo.label, isNot(contains('build')));
  });
}

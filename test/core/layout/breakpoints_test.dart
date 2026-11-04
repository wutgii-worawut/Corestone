import 'package:corestone/core/layout/breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('window size classes follow the Material 3 breakpoints', () {
    expect(WindowSize.fromWidth(0), WindowSize.compact);
    expect(WindowSize.fromWidth(599), WindowSize.compact);
    expect(WindowSize.fromWidth(600), WindowSize.medium);
    expect(WindowSize.fromWidth(839), WindowSize.medium);
    expect(WindowSize.fromWidth(840), WindowSize.expanded);
    expect(WindowSize.fromWidth(1280), WindowSize.expanded);
  });
}

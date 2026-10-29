import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/routing/redirect.dart';

void main() {
  test('parent routes stay behind the gate', () {
    expect(
      redirectFor(
        location: '/parent',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
      ),
      '/parent/gate',
    );
    expect(
      redirectFor(
        location: '/parent/language',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
      ),
      '/parent/gate',
    );
    expect(
      redirectFor(
        location: '/parent/gate',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
      ),
      isNull,
    );
    expect(
      redirectFor(
        location: '/parent/gate',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: true,
      ),
      '/parent',
    );
    expect(
      redirectFor(
        location: '/',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
      ),
      isNull,
    );
  });

  test('a profile skips onboarding and a missing profile cannot open the child home', () {
    expect(
      redirectFor(
        location: '/welcome',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
      ),
      '/',
    );
    expect(
      redirectFor(
        location: '/',
        sessionLoading: false,
        hasProfile: false,
        gateUnlocked: false,
      ),
      '/welcome',
    );
    expect(
      redirectFor(
        location: '/loading',
        sessionLoading: true,
        hasProfile: false,
        gateUnlocked: false,
      ),
      isNull,
    );
    expect(
      redirectFor(
        location: '/',
        sessionLoading: true,
        hasProfile: false,
        gateUnlocked: false,
      ),
      '/loading',
    );
  });

  test('an ended reminder leaves child play and leaves parent pages alone', () {
    expect(
      redirectFor(
        location: '/',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
        sessionEnded: true,
      ),
      '/rest',
    );
    expect(
      redirectFor(
        location: '/c/animals',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
        sessionEnded: true,
      ),
      '/rest',
    );
    expect(
      redirectFor(
        location: '/a/animal.elephant.001',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
        sessionEnded: true,
      ),
      '/rest',
    );
    expect(
      redirectFor(
        location: '/parent',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: true,
        sessionEnded: true,
      ),
      isNull,
    );
    expect(
      redirectFor(
        location: '/rest',
        sessionLoading: false,
        hasProfile: true,
        gateUnlocked: false,
        sessionEnded: true,
      ),
      isNull,
    );
    expect(
      redirectFor(
        location: '/local',
        sessionLoading: false,
        hasProfile: false,
        gateUnlocked: false,
        sessionEnded: true,
      ),
      isNull,
    );
  });
}

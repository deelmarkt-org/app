import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/router/auth_guard.dart';

void main() {
  group('authRedirect', () {
    test('returns /splash when loading', () {
      expect(
        authRedirect(isLoading: true, isLoggedIn: false, currentPath: '/'),
        '/splash',
      );
    });

    test('redirects /sell to /onboarding when not logged in', () {
      expect(
        authRedirect(isLoading: false, isLoggedIn: false, currentPath: '/sell'),
        '/onboarding',
      );
    });

    test(
      'redirects /sell to /login when not logged in but onboarding complete',
      () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: false,
            currentPath: '/sell',
            isOnboardingComplete: true,
          ),
          '/login',
        );
      },
    );

    test('redirects /messages to /onboarding when not logged in', () {
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: false,
          currentPath: '/messages',
        ),
        '/onboarding',
      );
    });

    test('redirects /profile to /onboarding when not logged in', () {
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: false,
          currentPath: '/profile',
        ),
        '/onboarding',
      );
    });

    test(
      'redirects /splash to /onboarding when resolved and not logged in',
      () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: false,
            currentPath: '/splash',
          ),
          '/onboarding',
        );
      },
    );

    test(
      'redirects /splash to /login when resolved, not logged in, onboarding complete',
      () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: false,
            currentPath: '/splash',
            isOnboardingComplete: true,
          ),
          '/login',
        );
      },
    );

    test('redirects /splash to / when resolved and logged in', () {
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: '/splash',
        ),
        '/',
      );
    });

    test('allows / when not logged in', () {
      expect(
        authRedirect(isLoading: false, isLoggedIn: false, currentPath: '/'),
        isNull,
      );
    });

    test('allows /search when not logged in', () {
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: false,
          currentPath: '/search',
        ),
        isNull,
      );
    });

    test('redirects /onboarding to / when logged in', () {
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: '/onboarding',
        ),
        '/',
      );
    });

    test('redirects /login to / when logged in', () {
      expect(
        authRedirect(isLoading: false, isLoggedIn: true, currentPath: '/login'),
        '/',
      );
    });

    test('allows /sell when logged in', () {
      expect(
        authRedirect(isLoading: false, isLoggedIn: true, currentPath: '/sell'),
        isNull,
      );
    });

    test('allows / when logged in', () {
      expect(
        authRedirect(isLoading: false, isLoggedIn: true, currentPath: '/'),
        isNull,
      );
    });
  });

  group('GoRouterRefreshStream', () {
    test('notifies on stream events', () async {
      final controller = StreamController<int>();
      final stream = GoRouterRefreshStream(controller.stream);

      var notifyCount = 0;
      stream.addListener(() => notifyCount++);

      controller.add(1);
      // Pump event loop to allow stream event to be processed
      await Future<void>.delayed(Duration.zero);

      expect(notifyCount, equals(1));
      expect(controller.hasListener, isTrue);

      stream.dispose();
      await controller.close();
    });

    test('disposes without error', () {
      final controller = StreamController<int>();
      final stream = GoRouterRefreshStream(controller.stream);

      // Should not throw on dispose
      expect(() => stream.dispose(), returnsNormally);

      controller.close();
    });
  });
}

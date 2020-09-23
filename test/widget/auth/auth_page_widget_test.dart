import 'package:crowdleague/models/app/app_state.dart';
import 'package:crowdleague/reducers/app_reducer.dart';
import 'package:crowdleague/widgets/auth/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import '../../mocks/image_test_utils.dart';

void main() {
  group('Sign in', () {
    testWidgets('with default provider', (WidgetTester tester) async {
      // Setup the app state with expected values
      final initialAppState = AppState.init();
      // Create the test harness.
      final store = Store<AppState>(appReducer, initialState: initialAppState);
      final wut = AuthPage();
      final harness =
          StoreProvider<AppState>(store: store, child: MaterialApp(home: wut));

      await provideMockedNetworkImages(() async {
        // Tell the tester to build the widget tree.
        await tester.pumpWidget(harness);
      });

      // Create the Finders.
      final titleFinder = find.byType(AuthPage);

      // Use the `findsOneWidget` matcher provided by flutter_test to verify
      // that AuthPage is shown
      expect(titleFinder, findsOneWidget);
    });
  });
}

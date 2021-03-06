import 'package:built_collection/built_collection.dart';
import 'package:crowdleague/actions/auth/store_auth_step.dart';
import 'package:crowdleague/actions/auth/store_user.dart';
import 'package:crowdleague/actions/auth/update_email_auth_options_page.dart';
import 'package:crowdleague/actions/navigation/add_problem.dart';
import 'package:crowdleague/actions/navigation/remove_current_page.dart';
import 'package:crowdleague/enums/auth/auth_step.dart';
import 'package:crowdleague/models/problems/apple_sign_in_problem.dart';
import 'package:crowdleague/models/problems/email_sign_in_problem.dart';
import 'package:crowdleague/models/problems/google_sign_in_problem.dart';
import 'package:crowdleague/models/problems/sign_out_problem.dart';
import 'package:crowdleague/services/auth_service.dart';
import 'package:crowdleague/utils/problem_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../mocks/auth/apple_signin_mocks.dart';
import '../../mocks/auth/firebase_auth_mocks.dart';
import '../../mocks/auth/google_signin_mocks.dart';
import '../../mocks/mock_firebase_platform.dart';

void main() {
  // set up firebase
  setUp(() {
    Firebase.delegatePackingProperty = MockFirebasePlatform();
  });
  group('Auth Service', () {
    // has a method that returns a stream that emits user

    test('provides a stream of user objects', () {
      final service =
          AuthService(FakeFirebaseAuth1(), FakeGoogleSignIn(), null);

      service.streamOfStateChanges.listen(expectAsync1((action) {
        expect(action is StoreUser, true);
      }, count: 1));
    });

    test('googleSignInStream resets auth steps on cancel', () {
      final service =
          AuthService(FakeFirebaseAuth1(), FakeGoogleSignInCancels(), null);

      // the service should set auth step to signing in with google
      // then due to user cancel (which means google sign in returns null)
      // the service should reset the auth step to waiting for input
      final expectedAuthSteps = [
        AuthStep.signingInWithGoogle,
        AuthStep.waitingForInput
      ];

      service.googleSignInStream.listen(expectAsync1((action) {
        expect((action as StoreAuthStep).step, expectedAuthSteps.removeAt(0));
      }, count: 2));
    });

    /// Setup an [AuthService] with mocks so the googleSignInStream
    /// emits the same sequence of [ReduxAction]s as a normal sign in
    test('googleSignInStream emits StoreAuthStep actions at each stage', () {
      final service =
          AuthService(FakeFirebaseAuth1(), FakeGoogleSignIn(), null);

      expect(
          service.googleSignInStream,
          emitsInOrder(<dynamic>[
            StoreAuthStep(step: AuthStep.signingInWithGoogle),
            StoreAuthStep(step: AuthStep.signingInWithFirebase),
            StoreAuthStep(step: AuthStep.waitingForInput),
            RemoveCurrentPage(),
            emitsDone
          ]));
    });

    test('googleSignInStream catches errors and emits AddProblem actions',
        () async {
      final service =
          AuthService(FakeFirebaseAuth1(), FakeGoogleSignInThrows(), null);

      /// The service will emit the google sign in step then the google signin
      /// object throws and the service catches the exception then emits
      /// an action to reset the auth step then emits a problem with
      /// info about the exception.
      ///
      /// We use a [TypeMatcher] as it's difficult to create the expected
      /// [Problem] due to the [Problem.trace] member
      expect(
          service.googleSignInStream,
          emitsInOrder(<dynamic>[
            StoreAuthStep(step: AuthStep.signingInWithGoogle),
            StoreAuthStep(step: AuthStep.waitingForInput),
            TypeMatcher<AddProblem>()
              ..having((p) => p, 'type', GoogleSignInProblem)
              ..having((p) => p.problem.message, 'message',
                  equals('Exception: GoogleSignIn.signIn')),
            emitsDone
          ]));
    });

    test('appleSignInStream resets auth steps on cancel', () {
      final service =
          AuthService(FakeFirebaseAuth1(), null, FakeAppleSignInCancels());

      /// The service should set auth step to signingInWithApple
      /// then due to user cancel the service should reset the UI.
      expect(
          service.appleSignInStream,
          emitsInOrder(<dynamic>[
            StoreAuthStep(step: AuthStep.signingInWithApple),
            StoreAuthStep(step: AuthStep.waitingForInput),
            emitsDone
          ]));
    });

    test('appleSignInStream emits StoreAuthStep actions at each stage', () {
      final service = AuthService(FakeFirebaseAuth1(), null, FakeAppleSignIn());

      /// The service will emit [StoreAuthStep] with [AuthStep.signingInWithApple]
      /// then another [StoreAuthStep], with [AuthStep.signingInWithFirebase].
      /// The apple signin object then throws, the service catches the exception
      /// and (in order to reset the UI) emits [StoreAuthStep] with
      /// [AuthStep.waitingForInput]. Finally the service emits [AddProblem]
      /// with a problem that has info about the exception.
      ///
      /// We use a [TypeMatcher] as it's difficult to create the expected
      /// [Problem] due to the [Problem.trace] member
      expect(
          service.appleSignInStream,
          emitsInOrder(<dynamic>[
            StoreAuthStep(step: AuthStep.signingInWithApple),
            StoreAuthStep(step: AuthStep.signingInWithFirebase),
            StoreAuthStep(step: AuthStep.waitingForInput),
            TypeMatcher<AddProblem>()
              ..having((p) => p, 'type', AppleSignInProblem)
              ..having((p) => p.problem.message, 'message',
                  equals('Exception: AppleSignIn.signIn')),
            emitsDone
          ]));
    });

    // test that errors are handled by being passed to the store
    test('appleSignInStream catches errors and emits AddProblem actions',
        () async {
      final service =
          AuthService(FakeFirebaseAuth1(), null, FakeAppleSignInThrows());

      // the service will emit step 1 indicating apple signin is occuring
      // the apple signin throws and the service catches the exception then
      // emits an action to reset the auth step then emits a problem with info
      // about the exception
      expect(
          service.googleSignInStream,
          emitsInOrder(<dynamic>[
            TypeMatcher<StoreAuthStep>()..having((a) => a.step, 'step', 1),
            TypeMatcher<StoreAuthStep>()..having((a) => a.step, 'step', 0),
            TypeMatcher<AddProblem>()
              ..having((p) => p, 'type', AppleSignInProblem)
              ..having((p) => p.problem.message, 'message',
                  equals('Exception: AppleSignIn.signIn')),
            emitsDone,
          ]));
    });

    test(
        'emailSignInStream emits UpdateEmailAuthOptionsPage actions at each stage of successful sign in',
        () {
      final service = AuthService(FakeFirebaseAuth1(), null, null);

      expect(
          service.emailSignInStream('test@email.com', 'test_password'),
          emitsInOrder(<dynamic>[
            UpdateEmailAuthOptionsPage(step: AuthStep.signingInWithEmail),
            UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput),
            RemoveCurrentPage(),
            emitsDone,
          ]));
    });

    test(
        'emailSignInStream catches firebaseAuthExceptions and emits AddProblem actions',
        () async {
      // init service to throw firebaseAuthException on sign in
      final service =
          AuthService(FakeFirebaseAuthSignInException(), null, null);

      /// Check that authService emits [AddProblem] action with info
      /// from caught [firebaseAuthException].
      /// We use a [TypeMatcher] as it's difficult to create the expected
      /// [Problem] due to the [Problem.trace] member
      expect(
          service.emailSignInStream('test@email.com', 'test_password'),
          emitsInOrder(<dynamic>[
            UpdateEmailAuthOptionsPage(step: AuthStep.signingInWithEmail),
            UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput),
            TypeMatcher<AddProblem>()
              ..having((p) => p, 'type', EmailSignInProblem)
              ..having(
                  (p) => p.problem.info,
                  'info',
                  BuiltMap<String, Object>(
                      {'code': 'test error: cant find user'}))
              ..having((p) => p.problem.message, 'message',
                  equals('firebase auth exception error')),
            emitsDone
          ]));
    });

    test('emailSignInStream catches errors and emits AddProblem actions',
        () async {
      // Init service that throws exception when signing in with firebase
      final service = AuthService(FakeFirebaseAuthThrows(), null, null);

      /// Check that emailSignInStream emits AddProblem action with info from caught error.
      /// We use a [TypeMatcher] as it's difficult to create the expected
      /// [Problem] due to the [Problem.trace] member
      expect(
          service.emailSignInStream('test@email.com', 'test_password'),
          emitsInOrder(<dynamic>[
            UpdateEmailAuthOptionsPage(step: AuthStep.signingInWithEmail),
            UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput),
            TypeMatcher<AddProblem>()
              ..having((p) => p, 'type', EmailSignInProblem)
              ..having((p) => p.problem.message, 'message',
                  equals('firebase auth exception error')),
            emitsDone
          ]));
    });

    test('signOut signs out of all providers', () async {
      // init all auth providers
      final mockFireBaseAuth = MockFireBaseAuth();
      final mockGoogleSignIn = MockGoogleSignIn();
      final mockAppleSignIn = MockAppleSignIn();
      final authService =
          AuthService(mockFireBaseAuth, mockGoogleSignIn, mockAppleSignIn);

      await authService.signOut();

      verify(mockFireBaseAuth.signOut());
      verify(mockGoogleSignIn.signOut());
      // Sign in with Apple does not have a sign out feature, see #32: https://github.com/crowdleague/crowdleague/issues/32
    });

    test(
        'signOut catches errors signing out of google and returns AddProblem action ',
        () async {
      final authService = AuthService(
        MockFireBaseAuth(),
        FakeGoogleSignInThrows(),
        MockAppleSignIn(),
      );
      final testAddProblem = createAddProblem(SignOutProblem,
          'Exception: GoogleSignIn.signOut', StackTrace.current);

      final error = await authService.signOut() as AddProblem;

      expect(error.problem.message, testAddProblem.problem.message);
    });

    test(
        'signOut catches errors signing out of firebase and returns AddProblem action ',
        () async {
      final authService = AuthService(
        FakeFirebaseAuthThrows(),
        MockGoogleSignIn(),
        MockAppleSignIn(),
      );
      final testAddProblem = createAddProblem(SignOutProblem,
          'Exception: firebaseAuth.signOut', StackTrace.current);

      final error = await authService.signOut() as AddProblem;

      expect(error.problem.message, testAddProblem.problem.message);
    });
  });
}

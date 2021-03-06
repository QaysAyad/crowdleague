import 'package:crowdleague/actions/auth/clear_user_data.dart';
import 'package:crowdleague/actions/auth/store_auth_step.dart';
import 'package:crowdleague/actions/auth/store_user.dart';
import 'package:crowdleague/actions/auth/update_email_auth_options_page.dart';
import 'package:crowdleague/actions/navigation/remove_current_page.dart';
import 'package:crowdleague/actions/redux_action.dart';
import 'package:crowdleague/enums/auth/auth_step.dart';
import 'package:crowdleague/extensions/extensions.dart';
import 'package:crowdleague/models/problems/apple_sign_in_problem.dart';
import 'package:crowdleague/models/problems/email_sign_in_problem.dart';
import 'package:crowdleague/models/problems/email_sign_up_problem.dart';
import 'package:crowdleague/models/problems/google_sign_in_problem.dart';
import 'package:crowdleague/models/problems/sign_out_problem.dart';
import 'package:crowdleague/utils/problem_utils.dart';
import 'package:crowdleague/utils/wrappers/apple_signin_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _fireAuth;
  final GoogleSignIn _googleSignIn;
  final AppleSignInWrapper _appleSignIn;

  AuthService(this._fireAuth, this._googleSignIn, this._appleSignIn);

  // Map auth.User objects emitted by FirebaseAuth to a StoreUser action,
  // which can be dispatched by the store.
  // If the auth.User or the uid field is null, create an empty StoreUser
  // object that will set the user field of the AppState to null.
  Stream<ReduxAction> get streamOfStateChanges {
    return _fireAuth.authStateChanges().map<ReduxAction>((firebaseUser) {
      if (firebaseUser == null) {
        return ClearUserData();
      }
      return StoreUser(user: firebaseUser.toUser());
    });
  }

  Stream<ReduxAction> get googleSignInStream async* {
    // signal to change UI
    yield StoreAuthStep(step: AuthStep.signingInWithGoogle);

    try {
      final googleUser = await _googleSignIn.signIn();

      // if the user canceled signin, an error is thrown but it gets swallowed
      // by the signIn() method so we need to reset the UI and close the stream
      if (googleUser == null) {
        yield StoreAuthStep(step: AuthStep.waitingForInput);
        return;
      }

      // signal to change UI
      yield StoreAuthStep(step: AuthStep.signingInWithFirebase);

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      /// the auth info will be picked up by the listener on [onAuthStateChanged]
      /// and emitted by [streamOfStateChanges]
      await _fireAuth.signInWithCredential(credential);

      // we are signed in so reset the UI and pop anything on top of home
      yield StoreAuthStep(step: AuthStep.waitingForInput);
      yield RemoveCurrentPage();
    } catch (error, trace) {
      // reset the UI and display an alert

      yield StoreAuthStep(step: AuthStep.waitingForInput);
      // errors with code kSignInCanceledError are swallowed by the
      // GoogleSignIn.signIn() method so we can assume anything caught here
      // is a problem and send to the store for display
      yield createAddProblem(GoogleSignInProblem, error, trace);
    }
  }

  Stream<ReduxAction> get appleSignInStream async* {
    // signal to change UI
    yield StoreAuthStep(step: AuthStep.signingInWithApple);

    try {
      // get an AuthorizationCredentialAppleID
      final appleIdCredential = await _appleSignIn.getAppleIDCredential();

      // signal to change UI
      yield StoreAuthStep(step: AuthStep.signingInWithFirebase);

      // get an OAuthCredential
      final credential = OAuthProvider('apple.com').credential(
        idToken: appleIdCredential.identityToken,
        accessToken: appleIdCredential.authorizationCode,
      );

      // use the credential to sign in to firebase
      // successful sign in will update the onAuthStateChanged stream
      await FirebaseAuth.instance.signInWithCredential(credential);

      // we are signed in so reset the UI and pop anything on top of home
      yield StoreAuthStep(step: AuthStep.waitingForInput);
      yield RemoveCurrentPage();
    } on SignInWithAppleAuthorizationException catch (e) {
      // reset the UI and display an alert (if not canceled)
      yield StoreAuthStep(step: AuthStep.waitingForInput);
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          break;
        default:
          yield createAddProblem(
            AppleSignInProblem,
            e,
            StackTrace.current,
            <String, Object>{'code': e.code},
          );
      }
    } catch (error, trace) {
      // reset the UI and display an alert

      yield StoreAuthStep(step: AuthStep.waitingForInput);
      // any specific errors are caught and dealt with so we can assume
      // anything caught here is a problem and send to the store for display
      yield createAddProblem(AppleSignInProblem, error, trace);
    }
  }

  /// Tries to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// Errors:
  ///
  ///  * `ERROR_INVALID_EMAIL` - If the [email] address is malformed.
  ///  * `ERROR_WRONG_PASSWORD` - If the [password] is wrong.
  ///  * `ERROR_USER_NOT_FOUND` - If there is no user corresponding to the given [email] address, or if the user has been deleted.
  ///  * `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///  * `ERROR_TOO_MANY_REQUESTS` - If there was too many attempts to sign in as this user.
  ///  * `ERROR_OPERATION_NOT_ALLOWED` - Indicates that Email & Password accounts are not enabled.
  Stream<ReduxAction> emailSignInStream(String email, String password) async* {
    yield UpdateEmailAuthOptionsPage(step: AuthStep.signingInWithEmail);
    try {
      await _fireAuth.signInWithEmailAndPassword(
          email: email, password: password);
      // reset UI
      yield UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput);
      // successful sign in will update the onAuthStateChanged stream
      // but we should navigate back to home
      yield RemoveCurrentPage();
    } on FirebaseAuthException catch (e) {
      yield UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput);
      yield createAddProblem(EmailSignInProblem, e.message, StackTrace.current,
          <String, Object>{'code': e.code});
    } catch (error, trace) {
      // reset UI
      yield UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput);
      // display problem
      yield createAddProblem(EmailSignInProblem, error, trace);
    }
  }

  /// Tries to create a new user account with the given email address and password.
  ///
  /// If successful, it also signs the user into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// Errors:
  ///
  ///  * `ERROR_WEAK_PASSWORD` - If the password is not strong enough.
  ///  * `ERROR_INVALID_EMAIL` - If the email address is malformed.
  ///  * `ERROR_EMAIL_ALREADY_IN_USE` - If the email is already in use by a different account.
  Stream<ReduxAction> emailSignUpStream(String email, String password) async* {
    // set the UI to waiting
    yield UpdateEmailAuthOptionsPage(step: AuthStep.signingUpWithEmail);
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // reset UI
      yield UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput);
      // successful sign up will update the onAuthStateChanged stream
      // but we should navigate back to home
      yield RemoveCurrentPage();
    } on FirebaseAuthException catch (e) {
      yield UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput);
      yield createAddProblem(EmailSignUpProblem, e.message, StackTrace.current,
          <String, Object>{'code': e.code});
    } catch (error, trace) {
      // reset UI
      yield UpdateEmailAuthOptionsPage(step: AuthStep.waitingForInput);
      // display problem
      yield createAddProblem(EmailSignUpProblem, error, trace);
    }
  }

  Future<ReduxAction> signOut() async {
    try {
      await _fireAuth.signOut();
      await _googleSignIn.signOut();
    } catch (error, trace) {
      return createAddProblem(SignOutProblem, error, trace);
    }

    // we let the AuthStateObserver dispatch a ClearUserData action when it
    // observes the relevant event
    return null;
  }
}

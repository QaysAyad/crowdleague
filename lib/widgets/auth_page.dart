import 'package:flutter/material.dart' hide Action;
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:crowdleague/models/actions/sign_in_with_apple.dart';
import 'package:crowdleague/models/actions/sign_in_with_google.dart';
import 'package:crowdleague/models/app_state.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool supportsAppleSignIn = true;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, int>(
        distinct: true,
        converter: (store) => store.state.authStep,
        builder: (context, authState) {
          return Material(
            child: IndexedStack(
              alignment: Alignment.center,
              index: authState,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (supportsAppleSignIn)
                      AppleSignInButton(
                          style: AppleButtonStyle.black,
                          onPressed: () => StoreProvider.of<AppState>(context)
                              .dispatch(SignInWithApple())),
                    SizedBox(height: 50),
                    GoogleSignInButton(
                      onPressed: () => StoreProvider.of<AppState>(context)
                          .dispatch(SignInWithGoogle()),
                      darkMode: true, // default: false
                    )
                  ],
                ),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                      Text('Contacting Auth Provider...')
                    ]),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                      Text('Signing in with Firebase...')
                    ]),
              ],
            ),
          );
        });
  }
}

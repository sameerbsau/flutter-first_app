import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../scoped-models/main.dart';
import '../widgets/ui_elements/adaptive_progess_indicator.dart';
import '../models/auth.dart';

class AuthPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new _AuthPageState();
  }
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _slideAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );
    super.initState();
  }

  Map<String, dynamic> _formdata = {
    'email': null,
    'password': null,
    'acceptTerms': false
  };
  // String _emailValue;
  // String _passwordValue;
  // bool _termsValue = false;
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final TextEditingController _passwordTextController = TextEditingController();
  AuthMode _authMode = AuthMode.Login;

  DecorationImage _buildBackgroundImage() {
    return DecorationImage(
        fit: BoxFit.cover,
        colorFilter:
            ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.dstATop),
        image: AssetImage('assets/background.jpg'));
  }

  Widget _buildEmailTextField() {
    return TextFormField(
      decoration: InputDecoration(
          labelText: 'Email', filled: true, fillColor: Colors.white),
      keyboardType: TextInputType.emailAddress,
      validator: (String value) {
        if (value.isEmpty ||
            !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                .hasMatch(value)) {
          return 'Email ID is required';
        }
      },
      onSaved: (String value) {
        _formdata['email'] = value;
      },
    );
  }

  Widget _buildPasswordTextField() {
    return TextFormField(
      decoration: InputDecoration(
          labelText: 'Password', filled: true, fillColor: Colors.white),
      obscureText: true,
      controller: _passwordTextController,
      validator: (String value) {
        if (value.isEmpty || value.length < 6) {
          return 'Invalid password';
        }
      },
      onSaved: (String value) {
        print(value);
        _formdata['password'] = value;
      },
    );
  }

  Widget _buildPasswordConfirmTextField() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      child: SlideTransition(
        position: _slideAnimation,
        child: TextFormField(
          decoration: InputDecoration(
              labelText: 'Confirm Password',
              filled: true,
              fillColor: Colors.white),
          obscureText: true,
          validator: (String value) {
            if (_passwordTextController.text != value &&
                _authMode == AuthMode.Signup) {
              return 'Passwords do not match.';
            }
          },
        ),
      ),
    );
  }

  Widget _buildAcceptSwitch() {
    return SwitchListTile(
      value: _formdata['acceptTerms'],
      onChanged: (bool value) {
        setState(() {
          _formdata['acceptTerms'] = value;
        });
      },
      title: Text('Accept Terms'),
    );
  }

  void _submitForm(Function authenticate) async {
    if (!_formKey.currentState.validate() || !_formdata['acceptTerms']) {
      return;
    }
    
    _formKey.currentState.save();
    Map<String, dynamic> successInfo;
    successInfo = await authenticate(
        _formdata['email'], _formdata['password'], _authMode);

    if (successInfo['success']) {
      // Navigator.pushReplacementNamed(context, '/');
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('An error occured!'),
              content: Text(successInfo['message']),
              actions: <Widget>[
                RaisedButton(
                  child: Text('Okay'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    }

    // print(_emailValue);
    // print(_passwordValue);
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    //print('device width---' + deviceWidth.toString());
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Container(
        decoration: BoxDecoration(image: _buildBackgroundImage()),
        padding: EdgeInsets.all(10.0),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: targetWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    _buildEmailTextField(),
                    SizedBox(
                      height: 10.0,
                    ),
                    _buildPasswordTextField(),
                    SizedBox(
                      height: 10.0,
                    ),
                    _buildPasswordConfirmTextField(),
                    _buildAcceptSwitch(),
                    SizedBox(
                      height: 10.0,
                    ),
                    FlatButton(
                        child: Text(
                            'Switch to ${_authMode == AuthMode.Login ? 'SignUp' : 'Login'}'),
                        onPressed: () {
                          if (_authMode == AuthMode.Login) {
                            setState(() {
                              _authMode = AuthMode.Signup;
                            });
                            _controller.forward();
                          } else {
                            setState(() {
                              _authMode = AuthMode.Login;
                            });
                            _controller.reverse();
                          }
                        }),
                    SizedBox(
                      height: 10.0,
                    ),
                    ScopedModelDescendant<MainModel>(
                      builder: (BuildContext context, Widget child,
                          MainModel model) {
                        return model.isLoading
                            ?AdaptiveProgressIndicator()
                            : RaisedButton(
                                color: Theme.of(context).primaryColor,
                                child: Text(_authMode == AuthMode.Login
                                    ? 'LOGIN'
                                    : 'SignUp'),
                                onPressed: () =>
                                    _submitForm(model.authenticate),
                              );
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

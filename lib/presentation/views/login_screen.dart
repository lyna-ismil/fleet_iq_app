import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/api_config.dart';
import '../../constants/theme.dart';
import './widgets/custom_text_field.dart';
import './widgets/password_strength_indicator.dart';
import './widgets/social_login_button.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _loginWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        const String baseUrl = "$userEndpoint/login";

        var uri = Uri.parse(baseUrl);
        var response = await http.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": _emailController.text.trim(),
            "password": _passwordController.text.trim(),
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              "userId", data["user"]["_id"]); // ✅ Only save userId

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomeScreen()));

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Login Successful!")));
        } else {
          var errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage =
                errorData["message"] ?? "Invalid email or password.";
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Server connection failed. Check your network.";
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 60),
                _buildHeader(),
                SizedBox(height: 40),
                _buildLoginForm(),
                SizedBox(height: 32),
                _buildSignUpLink(),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome",
          style: Theme.of(context).textTheme.displayLarge,
        ).animate().fadeIn(duration: 600.ms).slideX(),
        SizedBox(height: 8),
        Text(
          "Sign in to access your fleet",
          style: Theme.of(context).textTheme.bodyMedium,
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CustomTextField(
            controller: _emailController,
            hintText: "Email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          CustomTextField(
            controller: _passwordController,
            hintText: "Password",
            icon: Icons.lock_outline,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: AppTheme.textMuted,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          PasswordStrengthIndicator(password: _passwordController.text),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ForgotPasswordScreen()),
                );
              },
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: AppTheme.brandBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildLoginButton(),
          SizedBox(height: 40),
          _buildSocialLoginButtons(),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _loginWithEmailAndPassword,
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppTheme.surfaceWhite,
                strokeWidth: 2,
              ),
            )
          : Text("Login"),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppTheme.surfaceBorder)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Or sign in with",
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: AppTheme.surfaceBorder)),
          ],
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialLoginButton(
              icon: FontAwesomeIcons.google,
              color: AppTheme.textMain,
              onPressed: () {},
            ),
            SizedBox(width: 24),
            SocialLoginButton(
              icon: FontAwesomeIcons.apple,
              color: AppTheme.textMain,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SignUpScreen()),
          );
        },
        child: RichText(
          text: TextSpan(
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            children: [
              TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: "Sign Up",
                style: TextStyle(
                    color: AppTheme.textMain,
                    fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms);
  }
}


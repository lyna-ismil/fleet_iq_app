import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_config.dart';
import '../../constants/theme.dart';
import './widgets/custom_text_field.dart';
import './widgets/password_strength_indicator.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUpWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final url = Uri.parse("$userEndpoint/signup");

        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "fullName": _fullNameController.text.trim(),
            "email": _emailController.text.trim(),
            "phone": _phoneNumberController.text.trim(),
            "password": _passwordController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          var data = jsonDecode(response.body);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userId", data["user"]["_id"]);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup Successful! Please Login.")),
          );
        } else {
          var errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage = errorData["message"] ?? "Signup failed. Try again.";
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
              children: [
                SizedBox(height: 60),
                FadeInDown(
                  duration: Duration(milliseconds: 600),
                  child: Text(
                    "Create Account",
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                SizedBox(height: 8),
                FadeInDown(
                  duration: Duration(milliseconds: 600),
                  child: Text(
                    "Sign up to get started",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                SizedBox(height: 40),

                // Standard Form
                FadeInUp(
                  duration: Duration(milliseconds: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: _fullNameController,
                          hintText: "Full Name",
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Please enter your full name';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        CustomTextField(
                          controller: _emailController,
                          hintText: "Email",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || !value.contains('@'))
                              return 'Please enter a valid email';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        CustomTextField(
                          controller: _phoneNumberController,
                          hintText: "Phone Number",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.length < 8)
                              return 'Please enter a valid phone number';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: "Password",
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 6)
                              return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        PasswordStrengthIndicator(
                            password: _passwordController.text),
                        SizedBox(height: 20),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          hintText: "Confirm Password",
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.redAccent),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style:
                                          TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 32),
                        ElevatedButton(
                          onPressed:
                              _isLoading ? null : _signUpWithEmailAndPassword,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: AppTheme.surfaceWhite,
                                      strokeWidth: 2),
                                )
                              : Text("Create Account"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 56),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40),
                FadeInUp(
                  duration: Duration(milliseconds: 1000),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 14),
                          children: [
                            TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                  color: AppTheme.textMain,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_config.dart';
import '../../constants/theme.dart';
import 'home_screen.dart';
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
  bool _isEHouwiyaLoading = false;

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

  void _signUpWithEHouwiya() async {
    setState(() {
      _isEHouwiyaLoading = true;
    });

    // Mock: simulate e-Houwiya authentication delay
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isEHouwiyaLoading = false;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle,
                    color: AppTheme.success, size: 48),
              ),
              SizedBox(height: 20),
              Text(
                "e-Houwiya Authentication Successful (Mocked)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Your identity has been verified via Mobile ID.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text("Continue"),
              ),
            ],
          ),
        );
      },
    );
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
                SizedBox(height: 32),

                // e-Houwiya Button
                FadeInUp(
                  duration: Duration(milliseconds: 700),
                  child: _buildEHouwiyaButton(),
                ),

                SizedBox(height: 24),

                // Divider
                FadeInUp(
                  duration: Duration(milliseconds: 750),
                  child: Row(
                    children: [
                      Expanded(
                          child: Divider(color: AppTheme.surfaceBorder)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Or sign up with email",
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 14),
                        ),
                      ),
                      Expanded(
                          child: Divider(color: AppTheme.surfaceBorder)),
                    ],
                  ),
                ),

                SizedBox(height: 24),

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

  Widget _buildEHouwiyaButton() {
    const Color tunisianRed = Color(0xFFE70013);

    return GestureDetector(
      onTap: _isEHouwiyaLoading ? null : _signUpWithEHouwiya,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: tunisianRed, width: 2),
          boxShadow: [
            BoxShadow(
              color: tunisianRed.withOpacity(0.1),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isEHouwiyaLoading) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: tunisianRed,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Authenticating...",
                style: TextStyle(
                  color: tunisianRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tunisianRed,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.fingerprint,
                    color: AppTheme.surfaceWhite, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                "Sign up with e-Houwiya (Mobile ID)",
                style: TextStyle(
                  color: tunisianRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

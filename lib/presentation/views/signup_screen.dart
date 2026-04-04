import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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

  File? _idCardImage;
  File? _driverLicenseImage;
  String? _errorMessage;
  int _currentStep = 0;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<File> compressImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      img.Image resized = img.copyResize(image, width: 800);
      final compressedBytes = img.encodeJpg(resized, quality: 70);
      final compressedFile = File(file.path)..writeAsBytesSync(compressedBytes);
      return compressedFile;
    } else {
      return file;
    }
  }

  Future<void> _pickImage(bool isIdCard) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        if (isIdCard) {
          _idCardImage = File(pickedFile.path);
        } else {
          _driverLicenseImage = File(pickedFile.path);
        }
      });
    }
  }

  void _signUpWithEmailAndPassword() async {
    if (_formKey.currentState!.validate() &&
        _idCardImage != null &&
        _driverLicenseImage != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        const String baseUrl = "$userEndpoint/signup";
        var uri = Uri.parse(baseUrl);

        File compressedIdCard = await compressImage(_idCardImage!);
        File compressedDriverLicense =
            await compressImage(_driverLicenseImage!);

        var request = http.MultipartRequest('POST', uri);

        request.fields['fullName'] = _fullNameController.text.trim();
        request.fields['email'] = _emailController.text.trim();
        request.fields['phone'] = _phoneNumberController.text.trim();
        request.fields['password'] = _passwordController.text.trim();

        request.files.add(
            await http.MultipartFile.fromPath("cin", compressedIdCard.path));
        request.files.add(await http.MultipartFile.fromPath(
            "permis", compressedDriverLicense.path));

        var streamedResponse =
            await request.send().timeout(Duration(seconds: 60));
        var responseData = await streamedResponse.stream.bytesToString();

        if (streamedResponse.statusCode == 201) {
          var data = jsonDecode(responseData);

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
          var errorData = jsonDecode(responseData);
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
    } else {
      setState(() {
        _errorMessage =
            "All fields, including CIN & Permis images, are required!";
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
                FadeInUp(
                  duration: Duration(milliseconds: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepper(),
                        SizedBox(height: 32),
                        if (_currentStep == 0) ...[
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
                        ],
                        if (_currentStep == 1) ...[
                          _buildImagePicker(
                            label: "Upload Front of ID Card",
                            imageFile: _idCardImage,
                            onTap: () => _pickImage(true),
                            icon: Icons.credit_card_outlined,
                          ),
                          SizedBox(height: 20),
                          _buildImagePicker(
                            label: "Upload Driver's License",
                            imageFile: _driverLicenseImage,
                            onTap: () => _pickImage(false),
                            icon: Icons.drive_eta_outlined,
                          ),
                        ],
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
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 40),
                        _buildActionButton(),
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

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepIndicator(0, "Details", Icons.person_outline),
        Expanded(child: Divider(color: AppTheme.surfaceBorder, thickness: 2)),
        _buildStepIndicator(1, "Docs", Icons.file_present_outlined),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.brandBlue : AppTheme.surfaceWhite,
            border: Border.all(
              color: isActive ? AppTheme.brandBlue : AppTheme.surfaceBorder,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? AppTheme.surfaceWhite : AppTheme.textMuted,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.brandBlue : AppTheme.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.surfaceBorder, style: BorderStyle.solid),
        ),
        child: imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.brandLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppTheme.brandBlue, size: 28),
                  ),
                  SizedBox(height: 12),
                  Text(label,
                      style: TextStyle(
                          color: AppTheme.textMain,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text("Tap to select photo",
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 13)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check,
                          color: AppTheme.surfaceWhite, size: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : (_currentStep == 0 ? _nextStep : _signUpWithEmailAndPassword),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: AppTheme.surfaceWhite, strokeWidth: 2),
            )
          : Text(_currentStep == 0 ? "Next" : "Complete Sign Up"),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 56),
      ),
    );
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _currentStep = 1;
      });
    }
  }
}

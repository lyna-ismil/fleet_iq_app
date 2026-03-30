import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../../constants/api_config.dart';
import '../../constants/theme.dart';
import './widgets/custom_text_field.dart';

class ReclamationScreen extends StatefulWidget {
  @override
  _ReclamationScreenState createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Select an image
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Submit Reclamation
  void _submitReclamation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString("userId");

        if (userId == null || userId.isEmpty) {
          setState(() {
            _errorMessage = "User session expired. Please log in again.";
            _isLoading = false;
          });
          return;
        }

        const String baseUrl = "$userEndpoint/reclamations";
        var uri = Uri.parse(baseUrl);
        var request = http.MultipartRequest("POST", uri);

        request.fields["id_user"] = userId;
        request.fields["message"] = _descriptionController.text.trim();

        if (_image != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', _image!.path),
          );
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          setState(() {
            _descriptionController.clear();
            _titleController.clear();
            _image = null;
            _isLoading = false;
          });

          _showSuccessDialog();
        } else {
          var errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage = "Reclamation failed: ${errorData['message']}";
            _isLoading = false;
          });
          _showErrorSnackBar(_errorMessage!);
        }
      } catch (e) {
        print("Error: $e");
        setState(() {
          _errorMessage = "Server connection failed. Check your network.";
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          ),
          backgroundColor: AppTheme.surfaceWhite,
          child: Container(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.success,
                    size: 64,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "Success!",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.success,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Your request has been submitted successfully.\nWe'll get back to you soon.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => HomeScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                  ),
                  child: Text("Return to Home"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.surfaceWhite),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        iconTheme: IconThemeData(color: AppTheme.textMain),
        title: Text(
          "Support Request",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card with illustration
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.brandLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.support_agent_outlined,
                            size: 48,
                            color: AppTheme.brandBlue,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        "How Can We Help You?",
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Fill out the form below and our support team will get back to you as soon as possible",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Form card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Request Details", Icons.description_outlined),
                        SizedBox(height: 24),

                        // Title field
                        CustomTextField(
                          controller: _titleController,
                          hintText: "Title (e.g., App Crash)",
                          icon: Icons.title,
                          validator: (value) =>
                              value == null || value.isEmpty ? "Title is required" : null,
                        ),
                        SizedBox(height: 20),

                        // Description field (we'll implement custom multi-line text field logic)
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: "Please describe your issue in detail...",
                            filled: true,
                            fillColor: AppTheme.surfaceGray,
                            contentPadding: EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                              borderSide: BorderSide(color: AppTheme.brandBlue, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                              borderSide: BorderSide(color: AppTheme.danger, width: 1),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? "Description is required" : null,
                        ),
                        
                        SizedBox(height: 32),

                        // Image attachment section
                        _buildSectionHeader("Attachments", Icons.attach_file),
                        SizedBox(height: 8),
                        Text(
                          "Add photos to help us understand your issue better (optional)",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 16),
                        _buildImagePicker(),
                        SizedBox(height: 40),

                        // Submit button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitReclamation,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 56),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.surfaceWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text("Submit Request"),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Contact info card
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone_in_talk_outlined,
                            color: AppTheme.surfaceWhite, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Need urgent help?",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.surfaceWhite,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Call us at +(216) 94 971 606",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.surfaceWhite.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceGray,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _image != null ? AppTheme.brandBlue : AppTheme.surfaceBorder,
              width: _image != null ? 2 : 1,
            ),
          ),
          child: _image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl - 2),
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "No image selected",
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.photo_library_outlined),
                label: Text("Gallery"),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 48),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: Icon(Icons.camera_alt_outlined),
                label: Text("Camera"),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../../constants/api_config.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import './widgets/custom_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _profileImage;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isVerified = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authState = ref.read(authProvider);
    final userId = authState.userId;

    if (userId == null) {
      setState(() {
        _errorMessage = "Session expired. Please log in again.";
      });
      return;
    }

    // If we already have user data from the provider, populate fields
    if (authState.user != null) {
      setState(() {
        _fullNameController.text = authState.user!.fullName;
        _emailController.text = authState.user!.email;
        _phoneController.text = authState.user!.phone ?? "";
        _isVerified = authState.user!.isVerified;
      });
      return;
    }

    // Otherwise fetch fresh
    try {
      final response = await http.get(Uri.parse("$userEndpoint/$userId"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"] ?? data;

        setState(() {
          _fullNameController.text = user["fullName"] ?? "";
          _emailController.text = user["email"] ?? "";
          _phoneController.text = user["num_phone"] ?? "";
          _isVerified = user["isVerified"] ?? false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load profile";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Server connection failed. Check your network.";
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = ref.read(authProvider).userId;

      if (userId == null) {
        setState(() {
          _errorMessage = "Session expired. Please log in again.";
          _isLoading = false;
        });
        return;
      }

      try {
        const String baseUrl = "$userEndpoint";
        var uri = Uri.parse("$baseUrl/$userId");

        var request = http.MultipartRequest('PUT', uri);
        request.fields['num_phone'] = _phoneController.text.trim();

        if (_profileImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'profile_picture',
            _profileImage!.path,
          ));
        }

        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          var data = jsonDecode(responseData);

          setState(() {
            _phoneController.text = data["user"]["num_phone"];
            if (data["user"]["profile_picture"] != null) {
              _profileImage = File(data["user"]["profile_picture"]);
            }
            _isLoading = false;
          });

          // Refresh user profile in the auth provider
          await ref.read(authProvider.notifier).refreshUserProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile Updated Successfully! ✅")),
          );
        } else {
          var errorData = jsonDecode(responseData);
          setState(() {
            _errorMessage = "Profile update failed: ${errorData['message']}";
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Server connection failed. Check your network.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        title: Text("My Profile", style: Theme.of(context).textTheme.displaySmall),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textMain),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppTheme.danger, fontSize: 13))),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      _buildProfilePicture(),
                      SizedBox(height: 24),
                      _buildVerificationBadge(),
                      SizedBox(height: 32),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Hero(
      tag: 'profilePicture',
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceWhite,
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: AppTheme.brandLight, width: 4),
              ),
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : Icon(Icons.person_outline, size: 48, color: AppTheme.brandBlue),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surfaceWhite, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: AppTheme.surfaceWhite, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isVerified ? AppTheme.success.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isVerified ? Icons.verified : Icons.error_outline,
            color: _isVerified ? AppTheme.success : AppTheme.danger,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            _isVerified ? "Verified User" : "Not Verified",
            style: TextStyle(
              color: _isVerified ? AppTheme.success : AppTheme.danger,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Personal Information", style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: 24),
          _buildTextField(Icons.person_outline, "Full Name", _fullNameController, "Enter your full name"),
          SizedBox(height: 20),
          _buildTextField(Icons.email_outlined, "Email", _emailController, "Enter your email", readOnly: true),
          SizedBox(height: 20),
          _buildTextField(Icons.phone_outlined, "Phone Number", _phoneController, "Enter your phone number"),
          SizedBox(height: 32),
          _buildSaveButton(),
          SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, String label, TextEditingController controller, String hint, {bool readOnly = false}) {
    return CustomTextField(
      controller: controller,
      hintText: label,
      icon: icon,
      readOnly: readOnly,
      validator: (value) => value == null || value.isEmpty ? "$label is required" : null,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfile,
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2),
            )
          : Text("Save Changes"),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
              title: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text("Logout", style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _logout();
                  },
                ),
              ],
            );
          },
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.danger,
        side: BorderSide(color: AppTheme.danger.withOpacity(0.5)),
        minimumSize: Size(double.infinity, 56),
      ),
      child: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppTheme.surfaceWhite,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.brandLight, shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt_outlined, color: AppTheme.brandBlue),
                  ),
                  title: Text("Take Photo", style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.brandLight, shape: BoxShape.circle),
                    child: Icon(Icons.photo_library_outlined, color: AppTheme.brandBlue),
                  ),
                  title: Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

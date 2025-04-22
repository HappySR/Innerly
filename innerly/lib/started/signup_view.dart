import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/pages/pending_approval_screen.dart';
import '../services/auth_service.dart';
import '../services/role.dart';
import 'login_view.dart';

class TherapistSignUpPage extends StatefulWidget {
  const TherapistSignUpPage({super.key});

  @override
  State<TherapistSignUpPage> createState() => _TherapistSignUpPageState();
}

class _TherapistSignUpPageState extends State<TherapistSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  String? _selectedDoc;
  XFile? _selectedDocument;
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _pickDocument() async {
    if (_selectedDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select document type first')),
      );
      return;
    }

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (pickedFile != null) {
        setState(() => _selectedDocument = pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick document: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDocument == null) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.signUpTherapist(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        documentType: _selectedDoc!,
        documentFile: _selectedDocument!,
        specialization: _specializationController.text.trim(),
        bio: _bioController.text.trim(),
        hourlyRate: double.tryParse(_rateController.text) ?? 0,
      );

      if (user != null) {
        UserRole.isTherapist = true;
        UserRole.saveRole(true);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PendingApprovalScreen()),
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Registration failed: ${e.toString()}';

      // Handle specific Supabase errors
      if (e is PostgrestException) {
        if (e.code == '23502') {
          errorMessage = 'Missing required information';
        } else if (e.code == '23505') {
          errorMessage = 'Account already exists';
        } else if (e.code == '42501') {
          errorMessage = 'Permission denied - contact support';
        }
      } else if (e is StorageException) {
        errorMessage = 'Document upload failed: ${e.message}';
      } else if (e.toString().contains('violates foreign key constraint')) {
        errorMessage = 'Registration failed: Invalid document type';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Therapist Registration')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                type: TextInputType.name,
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                type: TextInputType.emailAddress,
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                type: TextInputType.text,
                isPassword: true,
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildTextField(
                controller: _specializationController,
                label: 'Specialization',
                type: TextInputType.text,
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                type: TextInputType.multiline,
                maxLines: 3,
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildTextField(
                controller: _rateController,
                label: 'Hourly Rate',
                type: TextInputType.number,
              ),
              SizedBox(height: screenSize.height * 0.02),

              // Document Selection
              DropdownButtonFormField<String>(
                value: _selectedDoc,
                decoration: InputDecoration(
                  labelText: 'Verification Document Type',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                items: const [
                  DropdownMenuItem(value: 'aadhaar', child: Text('Aadhaar Card')),
                  DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
                  DropdownMenuItem(value: 'license', child: Text('Professional License')),
                ],
                onChanged: (value) => setState(() => _selectedDoc = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              SizedBox(height: screenSize.height * 0.02),

              // Document Upload
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.02,
                  ),
                ),
                onPressed: _pickDocument,
                icon: const Icon(Icons.upload),
                label: Text(_selectedDocument?.name ?? 'Upload Document'),
              ),
              if (_selectedDocument != null)
                Padding(
                  padding: EdgeInsets.only(top: screenSize.height * 0.01),
                  child: Text(
                    'Selected: ${_selectedDocument!.name}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),

              SizedBox(height: screenSize.height * 0.04),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.02,
                  ),
                ),
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Register as Therapist'),
              ),

              SizedBox(height: screenSize.height * 0.02),

              // Sign In Button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInPage(),
                    ),
                  );
                },
                child: Text(
                  'Already have an account? Sign In',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType type,
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      keyboardType: type,
      obscureText: isPassword,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (isPassword && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}
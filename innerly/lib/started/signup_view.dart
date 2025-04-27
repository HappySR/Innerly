import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final TextEditingController _specializationController =
      TextEditingController();
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
            MaterialPageRoute(
              builder: (context) => const PendingApprovalScreen(),
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Registration failed: ${e.toString()}';
      if (e is PostgrestException) {
        if (e.code == '23502')
          errorMessage = 'Missing required information';
        else if (e.code == '23505')
          errorMessage = 'Account already exists';
        else if (e.code == '42501')
          errorMessage = 'Permission denied - contact support';
      } else if (e is StorageException) {
        errorMessage = 'Document upload failed: ${e.message}';
      } else if (e.toString().contains('violates foreign key constraint')) {
        errorMessage = 'Invalid document type';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create an account',
                    style: GoogleFonts.lora(
                      textStyle: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create your account. Enter your email and password',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _roundedField(controller: _nameController, hint: 'Full name'),
                _roundedField(
                  controller: _emailController,
                  hint: 'E-mail',
                  type: TextInputType.emailAddress,
                ),
                _roundedField(
                  controller: _passwordController,
                  hint: 'Password',
                  isPassword: true,
                ),
                _roundedField(
                  controller: _specializationController,
                  hint: 'Specialization',
                ),

                DropdownButtonFormField<String>(
                  value: _selectedDoc,
                  decoration: _dropdownDecoration('Document Type'),
                  style: GoogleFonts.rubik(color: Colors.black),
                  items: const [
                    DropdownMenuItem(
                      value: 'aadhaar',
                      child: Text('Aadhaar Card'),
                    ),
                    DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
                    DropdownMenuItem(
                      value: 'license',
                      child: Text('Professional License'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedDoc = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),

                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDocument,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDocument?.name ?? 'Verify Document',
                            style: GoogleFonts.rubik(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Opacity(opacity: 0.5, child: Icon(Icons.upload)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF719E07),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 45,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.rubik(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create account'),
                ),

                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: 'By clicking above, I agree to ',
                    style: GoogleFonts.rubik(fontSize: 18),
                    children: [
                      TextSpan(
                        text: 'Terms of service',
                        style: GoogleFonts.rubik(color: Colors.green),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: GoogleFonts.rubik(color: Colors.green),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Google sign-in logic
                  },
                  icon: Image.asset('assets/icons/google.png', height: 25),
                  label: Text(
                    'Continue with Google',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInPage()),
                    );
                  },
                  child: Text(
                    'Already have an account? Login',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      color: const Color(0xFF719E07), // Using your green
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.rubik(),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _roundedField({
    required TextEditingController controller,
    required String hint,
    TextInputType type = TextInputType.text,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        style: GoogleFonts.rubik(fontSize: 18), // Text inside input
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.rubik(
            fontSize: 16,
            color: const Color.fromARGB(255, 175, 174, 174),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ), // controls inner padding
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'This field is required';
          if (isPassword && value.length < 6) return 'Minimum 6 characters';
          return null;
        },
      ),
    );
  }
}

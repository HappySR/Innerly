import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/pages/bottom_nav.dart';
import '../home/pages/pending_approval_screen.dart';
import '../services/auth_service.dart';
import '../services/role.dart';
import 'signup_view.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.signInTherapist(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        UserRole.isTherapist = true;
        UserRole.saveRole(true);

        final therapistData =
            await _supabase
                .from('therapists')
                .select()
                .eq('id', _supabase.auth.currentUser!.id)
                .single();

        if (!mounted) return;

        switch (therapistData['document_status']) {
          case 'approved':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomNav()),
            );
            break;
          case 'pending':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PendingApprovalScreen(),
              ),
            );
            break;
          case 'rejected':
            throw 'Your account was rejected. Reason: ${therapistData['rejection_reason'] ?? 'Not specified'}';
          default:
            throw 'Invalid account status';
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 50),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Hey! Welcome back',
                            style: GoogleFonts.lora(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Create your account. Enter your email and password',
                          style: GoogleFonts.rubik(fontSize: 18),
                        ),
                        const SizedBox(height: 24),

                        // Email
                        _buildInputField(
                          label: 'E-mail',
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _buildInputField(
                          label: 'Password',
                          controller: _passwordController,
                          obscureText: true,
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

                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.rubik(
                              color: const Color(0xFF719E07),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton(
                            onPressed:
                                (_formKey.currentState?.validate() ?? false) &&
                                        !_isLoading
                                    ? _handleSignIn
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF719E07),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 94,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      'Log in',
                                      style: GoogleFonts.rubik(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('OR'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Google Button
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 400,
                            ), // adjust as needed
                            child: SizedBox(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.asset(
                                    'assets/icons/google.png',
                                    height: 24,
                                  ),
                                ),
                                label: Text(
                                  'Continue with Google',
                                  style: GoogleFonts.rubik(
                                    color: Colors.black87,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 34,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  shadowColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Create Account
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "I don't have an account. ",
                              style: GoogleFonts.rubik(),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TherapistSignUpPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Create account',
                                style: GoogleFonts.rubik(
                                  color: const Color(0xFF719E07),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.rubik(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.rubik(
          fontSize: 16,
          color: Colors.black45,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

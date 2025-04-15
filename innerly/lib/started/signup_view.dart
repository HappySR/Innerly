import 'package:flutter/material.dart';
import '../home/pages/bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/role.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedDoc;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      body: SafeArea(
        child: Column(
          children: [
            // Top banner
            Container(
              height: 180,
              decoration: const BoxDecoration(color: Color(0xFFFDF5E6)),
              alignment: Alignment.center,
              child: Image.asset('assets/icons/leaf.png', height: 80),
            ),

            // Form section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFD3D7DA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(200),
                    topRight: Radius.circular(200),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.green, width: 3.0),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(55, 100, 55, 30),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Create an account',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildLabel("Full Name"),
                      _buildTextField(
                        controller: _nameController,
                        hint: "Enter your full name",
                        obscure: false,
                      ),

                      const SizedBox(height: 16),
                      _buildLabel("Email"),
                      _buildTextField(
                        controller: _emailController,
                        hint: "abc@example.com",
                        obscure: false,
                      ),

                      const SizedBox(height: 16),
                      _buildLabel("Password"),
                      _buildTextField(
                        controller: _passwordController,
                        hint: "At least 8 characters",
                        obscure: true,
                        icon: Icons.visibility_off,
                      ),

                      const SizedBox(height: 16),
                      _buildLabel("Verification Document (optional)"),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                                border: const Border(
                                  bottom: BorderSide(
                                    color: Colors.grey,
                                    width: 3.0,
                                  ),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedDoc,
                                  hint: const Text(
                                    "Upload your document here...",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'aadhaar',
                                      child: Text("Aadhaar Card"),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pan',
                                      child: Text("PAN Card"),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDoc = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: const Icon(Icons.upload, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isFormValid
                                    ? const Color(0xFF4E7159)
                                    : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed:
                              _isFormValid
                                  ? () async {
                                    UserRole.isTherapist = true;
                                    UserRole.saveRole(true);
                                    final authService = AuthService();
                                    await authService.handleAnonymousLogin();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BottomNav(),
                                      ),
                                    );
                                  }
                                  : null,
                          child: const Text(
                            "Sign in",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Center(child: Text("Or sign in with")),
                      const SizedBox(height: 12),

                      // Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2DCDC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {},
                          icon: const Icon(
                            Icons.g_mobiledata,
                            color: Colors.red,
                            size: 30,
                          ),
                          label: const Text(
                            "Sign in with Google",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 3.0),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: icon != null ? Icon(icon) : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}

import 'package:flutter/material.dart';
import '../home/pages/bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/role.dart';

class UUIDInputPage extends StatefulWidget {
  @override
  _UUIDInputPageState createState() => _UUIDInputPageState();
}

class _UUIDInputPageState extends State<UUIDInputPage> {
  final TextEditingController _controller = TextEditingController();
  int _attemptsLeft = 3;
  String _message = '';

  void _validateUUID() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      showSnackBar('Please enter your UUID');
      return;
    }

    try {
      final authService = AuthService();
      final user = await authService.signInAnonymously(input);

      UserRole.isTherapist = false;
      UserRole.saveRole(false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNav()),
      );
    } catch (e) {
      handleError(e.toString());
    }
    _controller.clear();
  }

  void handleError(String error) {
    final message = error.replaceAll('Exception: ', '');
    setState(() {
      _attemptsLeft = _attemptsLeft > 0 ? _attemptsLeft - 1 : 0;
      _message = _attemptsLeft > 0
          ? '❌ $message. Attempts left: $_attemptsLeft'
          : '🚫 Account locked';
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 3),
        ),
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bool isLocked = _attemptsLeft == 0;


    return Scaffold(
      backgroundColor: Color(0xFFFFF7E7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Welcome',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    constraints: BoxConstraints(
                      maxHeight: height * 0.6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Already a User?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF719E07),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              labelText: 'Enter your UUID',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Color(0xFFFFF7E7),
                            ),
                            enabled: !isLocked,
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: isLocked ? null : _validateUUID,
                              child: Text(
                                'Submit',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF719E07),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                textStyle: TextStyle(fontSize: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_message.isNotEmpty) ...[
                            SizedBox(height: 20),
                            Text(
                              _message,
                              style: TextStyle(
                                color: isLocked ? Colors.red : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.all(20),
                    constraints: BoxConstraints(
                      maxHeight: height * 0.4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New here?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF719E07),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'If you are a new user, please register to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              UserRole.isTherapist = false;
                              UserRole.saveRole(false);
                              final authService = AuthService();
                              await authService.signUpAnonymously();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BottomNav()),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF719E07),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            textStyle: TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Register Now',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
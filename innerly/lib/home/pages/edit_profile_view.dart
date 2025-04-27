import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6E9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Handle back action
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(
                'assets/user/user.png',
              ), // therapist image
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF6E9),
                elevation: 0,
                side: const BorderSide(color: Colors.transparent),
              ),
              onPressed: () {
                // Handle change photo
              },
              child: const Text(
                'Change Photo',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 30),
            buildLabel('Display Name'),
            buildTextField('Kate'),
            const SizedBox(height: 20),
            buildLabel('Bio'),
            buildTextField('“A safe space seeker, finding\npeace in little moments.”', maxLines: 2),
            const SizedBox(height: 20),
            buildLabel('Languages'),
            buildDropdown('Languages you know'),
            const SizedBox(height: 20),
            buildLabel('Theme'),
            buildDropdown('Calm Blue'),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Handle Save Changes
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18,
                  color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildTextField(String hint, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildDropdown(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        hint: Text(hint),
        items: const [
          DropdownMenuItem(value: 'Black', child: Text('English')),
          DropdownMenuItem(value: 'White', child: Text('Spanish')),
          DropdownMenuItem(value: 'System Default', child: Text('French')),
        ],
        onChanged: (value) {
          // Handle dropdown changes
        },
      ),
    );
  }
}

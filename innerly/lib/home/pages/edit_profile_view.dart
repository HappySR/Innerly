import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProfilePage extends StatefulWidget {
  final String routeName;

  const EditProfilePage({Key? key, this.routeName = '/edit_profile'}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  List<String> _selectedLanguages = [];

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
            Navigator.pop(context);
          },
        ),
        title: Text(
          L10n.getTranslatedText(context, 'Edit Profile'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage('assets/user/user.png'), // therapist image
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF6E9),
                      elevation: 0,
                      side: const BorderSide(color: Colors.transparent),
                    ),
                    onPressed: () {
                      // Handle change photo
                    },
                    child: Text(
                      L10n.getTranslatedText(context, 'Change Photo'),
                      style: TextStyle(color: Colors.black,
                      fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            buildLabel(L10n.getTranslatedText(context, 'Display Name')),
            buildTextField('Kate'),
            const SizedBox(height: 20),
            buildLabel(L10n.getTranslatedText(context, 'Age')),
            buildAgeTextField(),
            const SizedBox(height: 20),
            buildLabel(L10n.getTranslatedText(context, 'Bio')),
            buildTextField(
              '“A safe space seeker, finding\npeace in little moments.”',
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            buildLabel('Languages'),
            buildMultiSelectLanguages(),
            const SizedBox(height: 20),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(30),
        child: SizedBox(
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
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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

  Widget buildAgeTextField() {
    return TextField(
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction(
              (oldValue, newValue) {
            // Block if empty or starts with 0
            if (newValue.text.isEmpty) return newValue;
            if (newValue.text == '0') return oldValue;
            return newValue;
          },
        ),
      ],
      decoration: InputDecoration(
        hintText: 'Enter your age',
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



  Widget buildDropdown(String hint, List<String> options) {
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
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          // Handle dropdown changes
        },
      ),
    );
  }

  Widget buildMultiSelectLanguages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedLanguages.map((language) {
          return Chip(
            label: Text(language),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () {
              setState(() {
                _selectedLanguages.remove(language);
              });
            },
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
      ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            hint: const Text('Languages you know'),
            items: _languages.map((language) {
              return DropdownMenuItem(
                value: language,
                child: Text(language),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && !_selectedLanguages.contains(value)) {
                setState(() {
                  _selectedLanguages.add(value);
                });
              }
            },
          ),
        ),
        const SizedBox(height: 10),

      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../localization/i10n.dart';


class EditTherapistProfileView extends StatefulWidget {
  const EditTherapistProfileView({Key? key}) : super(key: key);

  @override
  State<EditTherapistProfileView> createState() => _EditTherapistProfileViewState();
}

class _EditTherapistProfileViewState extends State<EditTherapistProfileView> {
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  List<String> _selectedLanguages = [];
  int? _selectedExperience;
  final List<int> _experienceYears = List.generate(30, (index) => index + 1);


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
            buildLabel(L10n.getTranslatedText(context, 'Bio')),
            buildTextField(
              L10n.getTranslatedText(context, '“A safe space seeker, finding\npeace in little moments.”'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            buildLabel(L10n.getTranslatedText(context, 'Age')),
            buildAgeTextField(),
            const SizedBox(height: 20),
            buildLabel(L10n.getTranslatedText(context, 'Languages')),
            buildMultiSelectLanguages(),
            const SizedBox(height: 20),
            buildLabel(L10n.getTranslatedText(context, 'Experience')),
            buildExperienceDropdown(),
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
            child: Text(
              L10n.getTranslatedText(context, 'Save Changes'),
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
        hintText: L10n.getTranslatedText(context, 'Enter your age'),
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
            hint: Text(L10n.getTranslatedText(context, 'Languages you know')),
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


  Widget buildExperienceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14), // Adjusts vertical padding
        ),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        dropdownColor: Colors.white,
        hint: Text(
          L10n.getTranslatedText(context, 'Select years of experience'),
          style: TextStyle(fontSize: 16),
        ),
        value: _selectedExperience,
        items: _experienceYears.map((year) {
          return DropdownMenuItem(
            value: year,
            child: Text('$year ${L10n.getTranslatedText(context, 'years')}'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedExperience = value;
          });
        },
        menuMaxHeight: 250, // Limits height to ~5 items with scroll
      ),
    );
  }
}
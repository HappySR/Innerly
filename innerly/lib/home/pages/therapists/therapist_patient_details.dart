import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class PatientDetails extends StatelessWidget {
  const PatientDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          L10n.getTranslatedText(context, 'PATIENTS'),
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          children: [
            // Full-width image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/patient_details.png',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // Details container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.getTranslatedText(context, 'Patient Details'),
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  detailRow(L10n.getTranslatedText(context, 'Name'), L10n.getTranslatedText(context, 'User'), context),
                  detailRow(L10n.getTranslatedText(context, 'Age'), '24', context),
                  const SizedBox(height: 8),
                  Text(
                    L10n.getTranslatedText(context, 'Condition'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    L10n.getTranslatedText(context, 'I\'m feeling overwhelmed by work lately, and it\'s been hard to relax'),
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  // Records label outside
                  Text(
                    L10n.getTranslatedText(context, 'Records'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  // Records box with only pencil icon inside
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${L10n.getTranslatedText(context, 'Attack Frequency')}: ${L10n.getTranslatedText(context, '3-4 times a week')}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(Icons.edit, size: 22, color: Colors.grey[700]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${L10n.getTranslatedText(context, 'Previous Diagnostics')}: ${L10n.getTranslatedText(context, '\nMeditation and prescribed sedatives')}',
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${L10n.getTranslatedText(context, 'Probable reasons')}: ${L10n.getTranslatedText(context, '\nShock, Extreme stress, Lack of sleep.')}',
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String title, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: value == L10n.getTranslatedText(context, 'User') ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

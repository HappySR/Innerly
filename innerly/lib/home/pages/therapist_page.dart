import 'package:flutter/material.dart';

class TherapistPage extends StatelessWidget {
  final List<Map<String, dynamic>> therapists;
  const TherapistPage({super.key, required this.therapists});

  @override
  Widget build(BuildContext context) {
    bool hasTherapists = therapists.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("THERAPIST"),
        titleTextStyle: const TextStyle(fontSize: 30, color: Colors.black),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child:
            hasTherapists
                ? ListView.builder(
                  itemCount: therapists.length,
                  itemBuilder: (context, index) {
                    final therapist = therapists[index];
                    return Container(
                      height: 100,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade50,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 70,
                            color: Color.fromARGB(205, 175, 223, 245),
                          ),
                          Expanded(child: Container()),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 12,
                            ), // Added right padding
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  therapist['name'],
                                  style: const TextStyle(fontSize: 27),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Oops!!! looks like no one is active currently.\nTry the best alternative and talk with lively...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue.shade50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Navigate to Lively screen
                      },
                      child: Column(
                        children: const [
                          Icon(Icons.eco, color: Colors.black, size: 40),
                          SizedBox(height: 10),
                          Text(
                            "Lively",
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

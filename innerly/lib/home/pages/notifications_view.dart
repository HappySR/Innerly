import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationBottomSheet extends StatelessWidget {
  const NotificationBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F9FF),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // Close the bottom sheet
                        },
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Mark as read',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text('TODAY',
                  style: GoogleFonts.aboreto(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700]
                  )),
              const SizedBox(height: 12),
              _notificationCard(
                'Reminder',
                'HEY, LET’S DO SOME MIND RELAXING EXERCISE. COME LET’S JOIN...',
                'assets/notification/cherry.png',
                '1m',
              ),
              _notificationCard(
                'Notification Title',
                'LETS CHAT WITH SOME OF OUR EXPERTS!!!!',
                'assets/notification/lollipop.png',
                '5m',
              ),
              _notificationCard(
                'Suggestion',
                'LETS CONNECT GLOBALLY...!!!!',
                'assets/notification/coffee.png',
                '24m',
              ),
              _notificationCard(
                'Admin',
                'SHARE YOUR REVIEW ABOUT YOUR EXPERIENCE. IT MEANS A LOT...',
                'assets/notification/orange.png',
                '26m',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _notificationCard(String title, String message, String imagePath, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 100,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(message,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.aboreto(fontSize: 13)),
                const SizedBox(height: 4),
                Text(time, style: GoogleFonts.poppins(fontSize: 10)),

              ],
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 4,
                backgroundColor: Colors.blue[700],
              )
            ],
          )
        ],
      ),
    );
  }
}

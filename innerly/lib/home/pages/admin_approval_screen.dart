// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class AdminApprovalScreen extends StatelessWidget {
//   const AdminApprovalScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Pending Approvals')),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: _supabase
//             .from('therapists')
//             .stream(primaryKey: ['id'])
//             .eq('document_status', 'pending'),
//         builder: (context, snapshot) {
//           // Display list of therapists with documents
//           return ListView.builder(
//             itemCount: snapshot.data?.length ?? 0,
//             itemBuilder: (context, index) {
//               final therapist = snapshot.data![index];
//               return ListTile(
//                 title: Text(therapist['name']),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Submitted: ${_formatTime(therapist['submission_time'])}'),
//                     _buildDocumentPreview(therapist['id']),
//                   ],
//                 ),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.check, color: Colors.green),
//                       onPressed: () => _approveTherapist(therapist['id']),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.red),
//                       onPressed: () => _rejectTherapist(therapist['id']),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _approveTherapist(String therapistId) async {
//     await _supabase.from('therapists').update({
//       'document_status': 'approved',
//       'approval_time': DateTime.now().toIso8601String(),
//       'is_approved': true,
//     }).eq('id', therapistId);
//   }
//
//   Future<void> _rejectTherapist(String therapistId) async {
//     // Show dialog to enter rejection reason
//     final reason = await showDialog<String>(...);
//
//     await _supabase.from('therapists').update({
//       'document_status': 'rejected',
//       'rejection_reason': reason,
//     }).eq('id', therapistId);
//   }
// }
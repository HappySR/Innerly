import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  static const _maxFileSizeMB = 5;
  static const _allowedExtensions = {'pdf', 'png', 'jpg', 'jpeg'};

  // In signInAnonymously() - ensure it looks like this:
  Future<User?> signInAnonymously() async {
    try {
      final response = await _supabase.auth.signInAnonymously();
      return response.user;
    } catch (e, stack) {
      print('Anonymous login error: $e\n$stack');
      rethrow;
    }
  }

  Future<User?> signUpTherapist({
    required String email,
    required String password,
    required String name,
    required String documentType,
    required XFile documentFile,
    String? specialization,
    String? bio,
    double? hourlyRate,
  }) async {
    try {
      final file = File(documentFile.path);
      await _validateDocument(file);

      // 1. Create auth user directly
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) throw Exception('User creation failed');

      // 2. Direct insert to therapists table
      final documentPath = await _uploadDocument(
        userId: user.id,
        documentType: documentType,
        file: file,
      );

      await Supabase.instance.client.from('therapists').insert({
        'id': user.id,
        'email': email,
        'name': name,
        'document_type': documentType,
        'document_path': documentPath,
        'document_status': 'pending',
        'submission_time': DateTime.now().toUtc().toIso8601String(),
        if (specialization != null) 'specialization': specialization,
        if (bio != null) 'bio': bio,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
      });

      return user;
    } catch (e, stack) {
      print('Therapist signup error: $e\n$stack');
      rethrow;
    }
  }

  Future<User?> signInTherapist({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw Exception('Authentication failed');

      final therapist = await _supabase
          .from('therapists')
          .select()
          .eq('id', user.id)
          .single();

      switch (therapist['document_status']) {
        case 'approved':
          await _updateOnlineStatus(user.id, true);
          return user;
        case 'pending':
          throw 'Account pending approval. Please wait 24-48 hours.';
        case 'rejected':
          throw 'Account rejected: ${therapist['rejection_reason'] ?? 'No reason provided'}';
        default:
          throw 'Invalid account status';
      }
    } catch (e, stack) {
      print('Therapist signin error: $e\n$stack');
      rethrow;
    }
  }

  Future<String> _uploadDocument({
    required String userId,
    required String documentType,
    required File file,
  }) async {
    try {
      final fileExt = _getFileExtension(documentType);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$documentType.$fileExt';
      final filePath = 'therapists/$userId/$fileName';

      await _supabase.storage
          .from('documents')
          .upload(
        filePath,
        file,
        fileOptions: FileOptions(
          contentType: _getMimeType(fileExt),
          upsert: false,
        ),
      );

      return filePath;
    } catch (e, stack) {
      print('Document upload error: $e\n$stack');
      rethrow;
    }
  }

  Future<void> _validateDocument(File file) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();
      final fileSizeMB = (await file.length()) / (1024 * 1024);

      if (!_allowedExtensions.contains(extension)) {
        throw 'Invalid file type. Allowed: ${_allowedExtensions.join(', ')}';
      }

      if (fileSizeMB > _maxFileSizeMB) {
        throw 'File size exceeds ${_maxFileSizeMB}MB';
      }
    } catch (e, stack) {
      print('Document validation error: $e\n$stack');
      rethrow;
    }
  }

  String _getFileExtension(String type) {
    switch (type.toLowerCase()) {
      case 'aadhaar':
      case 'pan':
        return 'pdf';
      case 'license':
        return 'jpg';
      default:
        return 'pdf';
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _supabase.from('therapists').update({
        'is_online': isOnline,
        'last_active': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (e, stack) {
      print('Online status update error: $e\n$stack');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _updateOnlineStatus(userId, false);
      }
      await _supabase.auth.signOut();
    } catch (e, stack) {
      print('Logout error: $e\n$stack');
      rethrow;
    }
  }

  String? get currentUserId => _supabase.auth.currentUser?.id;
}
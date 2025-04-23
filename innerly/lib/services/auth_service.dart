import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  static const _maxFileSizeMB = 5;
  static const _allowedExtensions = {'pdf', 'png', 'jpg', 'jpeg'};

  // Enhanced anonymous sign-in with session verification
  Future<User?> signInAnonymously() async {
    try {
      final response = await _supabase.auth.signInAnonymously();
      if (response.user == null) throw Exception('Anonymous login failed');

      debugPrint('Anonymous user created: ${response.user?.id}');
      return response.user;
    } catch (e, stack) {
      debugPrint('Anonymous login error: $e\n$stack');
      rethrow;
    }
  }

  // Comprehensive therapist sign-up with transaction safety
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

      // Create user account
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'role': 'therapist'},
      );

      final user = authResponse.user;
      if (user == null) throw Exception('User creation failed');

      // Upload document
      final documentPath = await _uploadDocument(
        userId: user.id,
        documentType: documentType,
        file: file,
      );

      // Create therapist profile in transaction
      await _supabase.from('therapists').insert({
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
      }).select().single();

      debugPrint('Therapist profile created for ${user.email}');
      return user;
    } catch (e, stack) {
      debugPrint('Therapist signup error: $e\n$stack');

      // Attempt cleanup if user was created but profile failed
      try {
        await _supabase.auth.admin.deleteUser(_supabase.auth.currentUser?.id ?? '');
      } catch (_) {}

      rethrow;
    }
  }

  // Secure therapist sign-in with status verification
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

      // Verify therapist status
      final therapist = await _supabase
          .from('therapists')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (therapist == null) throw Exception('Therapist profile not found');

      switch (therapist['document_status']) {
        case 'approved':
          await _updateOnlineStatus(user.id, true);
          debugPrint('Therapist ${user.email} signed in successfully');
          return user;
        case 'pending':
          throw 'Account pending approval. Please wait 24-48 hours.';
        case 'rejected':
          throw 'Account rejected: ${therapist['rejection_reason'] ?? 'No reason provided'}';
        default:
          throw 'Invalid account status';
      }
    } catch (e, stack) {
      debugPrint('Therapist signin error: $e\n$stack');
      rethrow;
    }
  }

  // Document handling utilities
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
      debugPrint('Document upload error: $e\n$stack');
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
      debugPrint('Document validation error: $e\n$stack');
      rethrow;
    }
  }

  // Therapist availability stream with robust filtering
  Stream<List<Map<String, dynamic>>> getAvailableTherapistsStream() {
    return _supabase
        .from('therapists')
        .stream(primaryKey: ['id'])
        .order('is_online', ascending: false)
        .map((data) {
      debugPrint('🔥 Raw therapist data received (${data.length} items)');

      final filtered = data.where((t) {
        try {
          final status = t['document_status']?.toString().trim().toLowerCase();
          final online = _parseBool(t['is_online']);

          if (status == 'approved' && online) {
            debugPrint('✅ Valid therapist: ${t['id']}');
            return true;
          }

          debugPrint('❌ Filtered out therapist: ${t['id']} '
              '(status: $status, online: $online)');
          return false;
        } catch (e) {
          debugPrint('Error filtering therapist ${t['id']}: $e');
          return false;
        }
      }).toList();

      debugPrint('🎯 Final filtered count: ${filtered.length}');
      return filtered;
    });
  }

  // Helper methods
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
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

      debugPrint('Updated online status for $userId: $isOnline');
    } catch (e, stack) {
      debugPrint('Online status update error: $e\n$stack');
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
      debugPrint('User logged out successfully');
    } catch (e, stack) {
      debugPrint('Logout error: $e\n$stack');
      rethrow;
    }
  }

  String? get currentUserId => _supabase.auth.currentUser?.id;
}
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();
  static const _maxFileSizeMB = 5;
  static const _allowedExtensions = {'pdf', 'png', 'jpg', 'jpeg'};

  Future<User?> signInAnonymously(String uuid) async {
    try {
      // 1. Lookup user by UUID
      final userRecord = await _supabase
          .from('users')
          .select('id, email, password')
          .eq('uuid', uuid.trim().toLowerCase())
          .maybeSingle();

      if (userRecord == null) throw Exception('Invalid UUID - please register first');

      // 2. Authenticate with stored credentials
      final response = await _supabase.auth.signInWithPassword(
        email: userRecord['email'] as String,
        password: userRecord['password'] as String,
      );

      return response.user;
    } on PostgrestException catch (e) {
      debugPrint('Database error: ${e.message}');
      throw Exception('Connection error - please try again later');
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      throw Exception('Authentication failed - ${e.message}');
    } catch (e, stack) {
      debugPrint('Signin error: $e\n$stack');
      throw Exception('Login failed - please check your credentials');
    }
  }

  Future<User?> signUpAnonymously() async {
    User? authUser;
    try {
      // 1. Create anonymous auth user
      final authResponse = await _supabase.auth.signInAnonymously();
      authUser = authResponse.user;
      if (authUser == null) throw Exception('Anonymous authentication failed');

      // 2. Generate UUID and credentials
      final uuid = _uuid.v4();
      final email = '${authUser.id}@innerly.com';
      final password = uuid;

      // 3. Convert to permanent account
      await _supabase.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
        ),
      );

      // 4. Store user metadata
      await _supabase.from('users').insert({
        'id': authUser.id,
        'uuid': uuid,
        'email': email,
        'password': password,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return authUser;
    } catch (e, stack) {
      debugPrint('Signup error: $e\n$stack');
      // Cleanup on error
      if (authUser != null) {
        await _supabase.auth.admin.deleteUser(authUser.id);
      }
      rethrow;
    }
  }

  Future<bool> checkUUIDExists(String uuid) async {
    try {
      final response = await _supabase
          .from('users')
          .select('uuid')
          .eq('uuid', uuid)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('UUID check error: $e');
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

  Stream<List<Map<String, dynamic>>> getChatHistoryStream(String userId) {
    return _supabase
        .from('private_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .execute()
        .map((messages) => messages.where((msg) =>
    msg['sender_id'] == userId || msg['receiver_id'] == userId).toList());
  }

  Future<Map<String, dynamic>> getTherapist(String therapistId) async {
    final response = await _supabase
        .from('therapists')
        .select()
        .eq('id', therapistId)
        .single();
    return response;
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
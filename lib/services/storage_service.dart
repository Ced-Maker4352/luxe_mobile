import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// StorageService handles persisting generated images/videos to Supabase Storage
/// and creating corresponding records in the `generations` table.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _supabase = Supabase.instance.client;

  static const String _bucketName = 'user-content';

  /// Save a generation result to Supabase Storage and insert a DB record.
  ///
  /// [imageBase64] - The base64-encoded image data (may include data URI prefix).
  /// [prompt] - The prompt used for generation.
  /// [style] - The style preset used (optional).
  /// [type] - The generation type: 'image', 'video', 'stitch', 'campus', 'logo'.
  /// [metadata] - Additional metadata as a Map (optional).
  ///
  /// Returns the public URL of the stored image, or null on failure.
  Future<String?> saveGeneration({
    required String imageBase64,
    required String prompt,
    String? style,
    String type = 'image',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('StorageService: No authenticated user. Skipping save.');
        return null;
      }

      // 1. Decode base64 to bytes
      final cleanBase64 = _stripDataUri(imageBase64);
      final Uint8List bytes = base64Decode(cleanBase64);

      // 2. Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = type == 'video' ? 'mp4' : 'jpg';
      final fileName = '${user.id}/${type}_$timestamp.$extension';

      // 3. Upload to Supabase Storage
      debugPrint(
        'StorageService: Uploading $fileName (${bytes.length} bytes)...',
      );

      final storagePath = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: type == 'video' ? 'video/mp4' : 'image/jpeg',
              upsert: true,
            ),
          );

      debugPrint('StorageService: Upload complete. Path: $storagePath');

      // 4. Get the public/signed URL
      final imageUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      // 5. Insert record into generations table
      await _supabase.from('generations').insert({
        'user_id': user.id,
        'storage_path': fileName,
        'image_url': imageUrl,
        'prompt': prompt.length > 2000 ? prompt.substring(0, 2000) : prompt,
        'style': style,
        'type': type,
        'metadata': metadata ?? {},
      });

      debugPrint('StorageService: Generation record saved. URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      // Storage errors should never block the user from seeing their result
      String errorMsg = e.toString();
      if (errorMsg.contains('Bucket not found')) {
        debugPrint(
          'StorageService ERROR: Bucket "$_bucketName" not found in Supabase! Please create it in the Supabase console.',
        );
      } else {
        debugPrint('StorageService: Error saving generation: $e');
      }
      return null;
    }
  }

  /// Delete a generation by its ID (removes from Storage and DB).
  Future<bool> deleteGeneration(String generationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // 1. Get the record to find the storage path
      final record = await _supabase
          .from('generations')
          .select('storage_path')
          .eq('id', generationId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (record == null) {
        debugPrint(
          'StorageService: Generation not found or not owned by user.',
        );
        return false;
      }

      final storagePath = record['storage_path'] as String?;

      // 2. Delete from Storage
      if (storagePath != null && storagePath.isNotEmpty) {
        await _supabase.storage.from(_bucketName).remove([storagePath]);
        debugPrint('StorageService: Deleted from storage: $storagePath');
      }

      // 3. Delete the DB record
      await _supabase
          .from('generations')
          .delete()
          .eq('id', generationId)
          .eq('user_id', user.id);

      debugPrint('StorageService: Generation $generationId deleted.');
      return true;
    } catch (e) {
      debugPrint('StorageService: Error deleting generation: $e');
      return false;
    }
  }

  /// Fetch all generations for the current user, ordered by newest first.
  /// [type] - Optional filter by generation type.
  /// [limit] - Max results (default 50).
  /// [offset] - Pagination offset.
  Future<List<Map<String, dynamic>>> fetchGenerations({
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      var query = _supabase
          .from('generations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (type != null && type != 'All') {
        query = _supabase
            .from('generations')
            .select()
            .eq('user_id', user.id)
            .eq('type', type.toLowerCase())
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
      }

      final data = await query;
      debugPrint('StorageService: Fetched ${data.length} generations.');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('StorageService: Error fetching generations: $e');
      return [];
    }
  }

  /// Strip data URI prefix from base64 strings.
  /// e.g. "data:image/jpeg;base64,/9j/4AAQ..." → "/9j/4AAQ..."
  String _stripDataUri(String input) {
    if (input.contains(',')) {
      return input.split(',').last;
    }
    return input;
  }
}

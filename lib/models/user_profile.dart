class UserProfile {
  final String id;
  final int photoGenerations;
  final int videoGenerations;
  final String? subscriptionTier;

  UserProfile({
    required this.id,
    this.photoGenerations = 0,
    this.videoGenerations = 0,
    this.subscriptionTier,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      // Map potential column names found in standard Supabase setups
      photoGenerations:
          json['photo_generations'] ?? json['generations_remaining'] ?? 0,
      videoGenerations: json['video_generations'] ?? 0,
      subscriptionTier: json['subscription_tier'] as String?,
    );
  }
}

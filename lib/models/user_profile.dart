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
    final tier = json['subscription_tier'] as String?;

    // Default credits if missing in DB
    int defaultPhotos = 0;
    if (tier != null) {
      if (tier.contains('creatorPack'))
        defaultPhotos = 30;
      else if (tier.contains('professionalShoot'))
        defaultPhotos = 80;
      else if (tier.contains('agencyMaster'))
        defaultPhotos = 200;
      else if (tier.contains('socialQuick'))
        defaultPhotos = 5;
    }

    return UserProfile(
      id: json['id'] as String,
      photoGenerations:
          json['photo_generations'] ??
          json['generations_remaining'] ??
          defaultPhotos,
      videoGenerations: json['video_generations'] ?? 0,
      subscriptionTier: tier,
    );
  }
}

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

    // Default video credits (e.g., 10 for Pro, 50 for Agency)
    int defaultVideos = 0;
    if (tier != null) {
      if (tier.contains('agency') || tier.contains('sub_monthly_99')) {
        defaultVideos = 50;
      } else if (tier.contains('pro') ||
          tier.contains('professional') ||
          tier.contains('sub_monthly_49')) {
        defaultVideos = 10;
      }
    }

    return UserProfile(
      id: json['id'] as String,
      photoGenerations:
          json['photo_generations'] ??
          json['generations_remaining'] ??
          defaultPhotos,
      videoGenerations: json['video_generations'] ?? defaultVideos,
      subscriptionTier: tier,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../shared/constants.dart';
import '../widgets/app_drawer.dart';
import '../services/storage_service.dart';
import '../widgets/video_result_viewer.dart';
import 'share_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _generations = [];
  bool _isLoading = true;
  bool _hasError = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  static const int _pageSize = 30;

  final List<String> _filters = [
    'All',
    'Image',
    'Video',
    'Stitch',
    'Campus',
    'Logo',
  ];

  @override
  void initState() {
    super.initState();
    _loadGenerations();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Infinite scroll listener
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  /// Initial load
  Future<void> _loadGenerations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await StorageService().fetchGenerations(
        type: _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase(),
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _generations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Gallery: Error loading generations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// Load more for pagination
  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final data = await StorageService().fetchGenerations(
        type: _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase(),
        limit: _pageSize,
        offset: _generations.length,
      );
      if (mounted) {
        setState(() {
          _generations.addAll(data);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Gallery: Error loading more: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  /// Pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadGenerations();
  }

  /// Delete a generation
  Future<void> _deleteGeneration(String id, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.softCharcoal,
        title: Text(
          'Delete Creation?',
          style: GoogleFonts.inter(color: AppColors.matteGold),
        ),
        content: Text(
          'This will permanently remove this creation.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await StorageService().deleteGeneration(id);
      if (success && mounted) {
        setState(() => _generations.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Creation deleted'),
            backgroundColor: AppColors.matteGold,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCharcoal,
      appBar: AppBar(
        backgroundColor: AppColors.midnightNavy,
        elevation: 0,
        title: Text(
          'GALLERY',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: AppColors.matteGold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.matteGold),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGenerations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.matteGold),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load gallery',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadGenerations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.matteGold,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    if (_generations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: AppColors.matteGold.withValues(alpha: 0.4),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No creations yet',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your first portrait in the Studio',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.matteGold,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: _generations.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _generations.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.matteGold),
                ),
              );
            }
            return _buildGalleryItem(_generations[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.midnightNavy,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.softCharcoal : Colors.white,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                  _loadGenerations(); // Re-fetch with new filter
                },
                selectedColor: AppColors.matteGold,
                backgroundColor: AppColors.softCharcoal,
                side: BorderSide(
                  color: AppColors.matteGold.withValues(alpha: 0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGalleryItem(Map<String, dynamic> generation, int index) {
    final imageUrl = generation['image_url'] as String?;
    final videoUrl = generation['video_url'] as String?;
    final prompt = generation['prompt'] as String? ?? '';
    final type = generation['type'] as String? ?? 'image';
    final createdAt = generation['created_at'] as String?;
    final id = generation['id'] as String;

    // Format relative time
    String timeAgo = '';
    if (createdAt != null) {
      final created = DateTime.tryParse(createdAt);
      if (created != null) {
        final diff = DateTime.now().difference(created);
        if (diff.inDays > 0) {
          timeAgo = '${diff.inDays}d ago';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inMinutes}m ago';
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.matteGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: AppColors.softCharcoal,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.matteGold.withValues(
                                  alpha: 0.5,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.softCharcoal,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 40,
                                color: AppColors.matteGold.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.softCharcoal,
                          child: Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: AppColors.matteGold.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                ),
                // Type badge
                if (type != 'image')
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.matteGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                // Action buttons
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.share,
                        onTap: () {
                          if (type == 'video' && videoUrl != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoResultViewer(
                                  videoUrl: videoUrl,
                                  title: prompt.isNotEmpty
                                      ? (prompt.length > 20
                                            ? '${prompt.substring(0, 20)}...'
                                            : prompt)
                                      : 'Video Result',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShareScreen(
                                imageUrl: imageUrl ?? '',
                                title: 'Luxe Creation',
                                description: prompt.length > 100
                                    ? prompt.substring(0, 100)
                                    : prompt,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        onTap: () => _deleteGeneration(id, index),
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt.isNotEmpty
                      ? (prompt.length > 40
                            ? '${prompt.substring(0, 40)}...'
                            : prompt)
                      : 'AI Creation',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timeAgo.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.midnightNavy.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 16, color: color ?? AppColors.matteGold),
      ),
    );
  }
}

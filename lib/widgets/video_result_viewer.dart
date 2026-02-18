import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../shared/constants.dart';

class VideoResultViewer extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const VideoResultViewer({super.key, required this.videoUrl, this.title});

  @override
  State<VideoResultViewer> createState() => _VideoResultViewerState();
}

class _VideoResultViewerState extends State<VideoResultViewer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.matteGold,
        handleColor: AppColors.matteGold,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white12,
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.matteGold),
        ),
      ),
      autoInitialize: true,
    );

    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player
          Center(
            child:
                _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(color: AppColors.matteGold),
          ),

          // Header Overlay
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title ?? 'LUXE CINEMATIC',
                      style: AppTypography.microBold(
                        color: AppColors.matteGold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Branding Overlay (Subtle)
          Positioned(
            bottom: 40,
            right: 20,
            child: Opacity(
              opacity: 0.3,
              child: Text(
                'LUXE STUDIO',
                style: AppTypography.microBold(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

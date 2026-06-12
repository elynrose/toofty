import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // Get the video's natural aspect ratio
    final aspectRatio = controller.value.aspectRatio;
    
    // Make it responsive - use LayoutBuilder to adapt to available space
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive size (use 90% of available space)
        double maxWidth = constraints.maxWidth * 0.9;
        double maxHeight = constraints.maxHeight * 0.9;
        
        // Calculate dimensions that maintain aspect ratio
        double videoWidth = maxWidth;
        double videoHeight = videoWidth / aspectRatio;
        
        // If calculated height exceeds available height, adjust
        if (videoHeight > maxHeight) {
          videoHeight = maxHeight;
          videoWidth = videoHeight * aspectRatio;
        }
        
        return Center(
          child: SizedBox(
            width: videoWidth,
            height: videoHeight,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

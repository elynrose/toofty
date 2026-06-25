import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_gate.dart';

/// Full-screen video splash — plays through before entering the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String splashVideoAsset = 'assets/videos/splash.mp4';
  static const String splashImageAsset = 'assets/images/splash.png';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _videoFinished = false;
  bool _appReady = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _appReady = true;
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(SplashScreen.splashVideoAsset);
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      controller
        ..setLooping(false)
        ..setVolume(0)
        ..addListener(_onVideoTick);

      setState(() {});
      await controller.play();
    } catch (e) {
      debugPrint('Splash video failed to load: $e');
      _videoFinished = true;
      _tryNavigate();
    }
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration == Duration.zero) return;

    final ended = position >= duration - const Duration(milliseconds: 200);
    if (ended && !_videoFinished) {
      _videoFinished = true;
      _tryNavigate();
    }
  }

  void _tryNavigate() {
    if (_navigated || !_appReady || !_videoFinished || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: controller != null && controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            : Image.asset(
                SplashScreen.splashImageAsset,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

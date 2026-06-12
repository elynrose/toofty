import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/brushing_activity.dart';
import '../models/monster_catalog.dart';
import '../providers/music_provider.dart';
import '../providers/child_provider.dart';
import '../widgets/circular_timer.dart';
import '../widgets/video_player_widget.dart';

class BrushingScreen extends StatefulWidget {
  const BrushingScreen({super.key});

  @override
  State<BrushingScreen> createState() => _BrushingScreenState();
}

class _BrushingScreenState extends State<BrushingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _currentTime = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentActivityIndex = 0;
  VideoPlayerController? _videoController;
  VideoPlayerController? _dancingVideoController;
  VideoPlayerController? _excitedVideoController; // Controller for excited video (shown between sessions)
  ConfettiController? _confettiController;
  List<BrushingActivityModel> _activities = [];
  double _videoOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 10));
    
    // Wait for provider to be ready before initializing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
      _loadExcitedVideo(); // Load excited video for between sessions
    });
  }
  
  void _updateTimerFromSettings() {
    if (!mounted) return;
    
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    if (childProvider.currentChild == null) return;
    
    // Update activities list from current child's settings
    final settings = childProvider.currentChild!.brushingSettings;
    _activities = settings.activities;
    
    if (_activities.isEmpty) return;
    
    if (_currentActivityIndex >= _activities.length) {
      _currentActivityIndex = 0;
    }
    
    final activity = _activities[_currentActivityIndex];
    final newTotalTime = activity.duration;
    
    // Update timer duration based on current state
    if (!_isPlaying && !_isPaused) {
      // Timer not started - update to new duration
      setState(() {
        _currentTime = newTotalTime;
      });
    } else if (_isPaused) {
      // Timer is paused - update to new duration
      setState(() {
        _currentTime = newTotalTime;
      });
    } else if (_isPlaying) {
      // Timer is running - calculate remaining time proportionally
      // or reset to new duration (simpler approach)
      final oldTotalTime = _currentTime + (_currentTime > 0 ? 0 : 1); // Avoid division by zero
      if (oldTotalTime > 0) {
        final progress = _currentTime / oldTotalTime;
        final newCurrentTime = (newTotalTime * progress).round();
        setState(() {
          _currentTime = newCurrentTime.clamp(0, newTotalTime);
        });
      } else {
        setState(() {
          _currentTime = newTotalTime;
        });
      }
    }
  }

  void _initializeVideo() {
    if (!mounted) return;
    
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    
    // Wait for provider to be initialized
    if (!childProvider.isInitialized || childProvider.currentChild == null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _initializeVideo();
        }
      });
      return;
    }
    
    // Update activities list from current child's settings
    final settings = childProvider.currentChild!.brushingSettings;
    _activities = settings.activities;
    
    if (_activities.isEmpty) return;
    
    if (_currentActivityIndex >= _activities.length) {
      _currentActivityIndex = 0;
    }
    
    final activity = _activities[_currentActivityIndex];
    setState(() {
      _currentTime = activity.duration;
    });
    
    // Initialize video - will be set to actual path when videos are provided
    _loadVideo(activity);
  }

  String _currentMonsterId() {
    final child = Provider.of<ChildProvider>(context, listen: false).currentChild;
    return child?.monsterId ?? MonsterCatalog.defaultId;
  }

  void _loadVideo(BrushingActivityModel activity) {
    final monsterId = _currentMonsterId();
    final videoPath = MonsterCatalog.videoAsset(monsterId, activity.videoFileName);

    // Fade out current video
    setState(() {
      _videoOpacity = 0.0;
    });
    
    // Wait a bit for fade, then load new video
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      try {
        _videoController?.dispose();
      } catch (e) {
        debugPrint('Error disposing old controller: $e');
      }
      
      try {
        _videoController = VideoPlayerController.asset(videoPath);
        
        _videoController!.initialize().then((_) {
          if (!mounted) return;
          
          try {
            _videoController!.setLooping(true);
            _videoController!.setVolume(1.0); // Ensure video audio is at full volume
            if (_isPlaying) {
              _videoController!.play();
            }
            // Fade in new video
            setState(() {
              _videoOpacity = 1.0;
            });
          } catch (e) {
            debugPrint('Error configuring video: $e');
            if (mounted) {
              setState(() {
                _videoController = null;
                _videoOpacity = 1.0;
              });
            }
          }
        }).catchError((error, stackTrace) {
          debugPrint('Error loading video: $error');
          debugPrint('Stack trace: $stackTrace');
          // Continue without video if it doesn't exist yet
          if (mounted) {
            setState(() {
              _videoController = null;
              _videoOpacity = 1.0;
            });
          }
        });
      } catch (e, stackTrace) {
        debugPrint('Error creating video controller: $e');
        debugPrint('Stack trace: $stackTrace');
        if (mounted) {
          setState(() {
            _videoController = null;
            _videoOpacity = 1.0;
          });
        }
      }
    });
  }

  void _loadExcitedVideo() {
    final videoPath = MonsterCatalog.intermissionVideo(_currentMonsterId());
    try {
      _excitedVideoController?.dispose();
      _excitedVideoController = VideoPlayerController.asset(videoPath);
      
      _excitedVideoController!.initialize().then((_) {
        if (!mounted) return;
        
        try {
          _excitedVideoController!.setLooping(true);
          _excitedVideoController!.setVolume(1.0);
          // Auto-play when loaded (since we're not playing yet)
          if (!_isPlaying) {
            _excitedVideoController!.play();
          }
          debugPrint('Excited video loaded and ready');
        } catch (e) {
          debugPrint('Error configuring excited video: $e');
        }
      }).catchError((error) {
        debugPrint('Error loading excited video: $error');
      });
    } catch (e) {
      debugPrint('Error creating excited video controller: $e');
    }
  }

  void _startTimer() {
    if (_isPaused) {
      _resumeTimer();
      return;
    }

    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });

    // Pause excited video and play activity video when timer starts
    _excitedVideoController?.pause();
    _videoController?.play();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime > 0) {
        setState(() {
          _currentTime--;
        });
      } else {
        _moveToNextActivity();
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
    _timer?.cancel();
    _videoController?.pause();
    
    // Show excited video when paused/stopped
    if (_excitedVideoController != null && 
        _excitedVideoController!.value.isInitialized) {
      _excitedVideoController!.play();
    }
  }

  void _resetSession() {
    setState(() {
      _currentActivityIndex = 0;
      _isPlaying = false;
      _isPaused = false;
    });
    _initializeVideo();
  }

  void _resumeTimer() {
    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });
    
    // Pause excited video and resume activity video
    _excitedVideoController?.pause();
    _videoController?.play();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime > 0) {
        setState(() {
          _currentTime--;
        });
      } else {
        _moveToNextActivity();
      }
    });
  }

  Future<void> _moveToNextActivity() async {
    _timer?.cancel();
    _videoController?.pause();
    
    // Show excited video between activities
    if (_excitedVideoController != null && 
        _excitedVideoController!.value.isInitialized) {
      _excitedVideoController!.play();
    }

    if (_currentActivityIndex < _activities.length - 1) {
      setState(() {
        _currentActivityIndex++;
        _isPlaying = false;
        _isPaused = false;
      });
      _initializeVideo();
    } else {
      // All activities completed - award points and record session
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      bool sessionRecorded = false;
      
      if (childProvider.currentChild != null) {
        sessionRecorded = await childProvider.recordBrushingSession(
          childProvider.currentChild!.id,
        );
      }
      
      setState(() {
        _isPlaying = false;
        _isPaused = false;
        _currentActivityIndex = 0;
      });
      
      if (sessionRecorded) {
        _showCompletionDialog();
      } else {
        // Already brushed twice today
        _showLimitReachedDialog();
      }
      
      // Show excited video after session completes
      if (_excitedVideoController != null && 
          _excitedVideoController!.value.isInitialized) {
        _excitedVideoController!.play();
      }
      
      _initializeVideo();
    }
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.accent, size: 32),
            SizedBox(width: 12),
            Text(
              'Daily Limit Reached!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You\'ve already brushed twice today! That\'s awesome! 🎉',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Come back tomorrow for more brushing fun!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.celebration,
              size: 80,
              color: AppColors.accent,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to children list
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 12,
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    // Start confetti
    _confettiController?.play();
    
    // Load dancing video (async, will appear in dialog when ready)
    _loadDancingVideo();
    
    // Show dialog immediately (video will appear when ready)
    // Show dialog immediately (video will appear when ready)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Use a StatefulBuilder to rebuild when video is ready
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Set up a one-time listener to rebuild dialog when video initializes
            void checkVideoState() {
              if (_dancingVideoController != null && 
                  _dancingVideoController!.value.isInitialized) {
                setDialogState(() {});
              }
            }
            
            // Check immediately
            checkVideoState();
            
            // Set up listener if video controller exists
            if (_dancingVideoController != null) {
              // Use a post-frame callback to add listener only once
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _dancingVideoController?.addListener(checkVideoState);
              });
            }
            
            return Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                // Confetti overlay
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController!,
                    blastDirection: math.pi / 2, // Downward
                    maxBlastForce: 5,
                    minBlastForce: 2,
                    emissionFrequency: 0.05,
                    numberOfParticles: 50,
                    gravity: 0.1,
                    shouldLoop: false,
                  ),
                ),
                // Dancing video and message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Great Job!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You\'ve completed your brushing routine!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      // Dancing video with smooth loading
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _dancingVideoController != null &&
                                _dancingVideoController!.value.isInitialized
                            ? ClipRRect(
                                key: const ValueKey('dancing-video'),
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: AspectRatio(
                                    aspectRatio: _dancingVideoController!.value.aspectRatio,
                                    child: VideoPlayer(_dancingVideoController!),
                                  ),
                                ),
                              )
                            : SizedBox(
                                key: const ValueKey('loading'),
                                width: 250,
                                height: 250,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _dancingVideoController?.pause();
                          _dancingVideoController?.dispose();
                          _dancingVideoController = null;
                          _confettiController?.stop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Awesome!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          },
        );
      },
    );
  }
  
  Future<void> _loadDancingVideo() async {
    final dancingPath = MonsterCatalog.celebrationVideo(_currentMonsterId());
    if (dancingPath == null) return;

    try {
      _dancingVideoController?.dispose();
      _dancingVideoController = VideoPlayerController.asset(dancingPath);
      
      await _dancingVideoController!.initialize();
      if (mounted) {
        _dancingVideoController!.setLooping(true);
        _dancingVideoController!.play();
        // Force rebuild to show video in dialog
        setState(() {});
        debugPrint('Dancing video loaded and playing - size: ${_dancingVideoController!.value.size}, aspectRatio: ${_dancingVideoController!.value.aspectRatio}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading dancing video: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _dancingVideoController = null;
        });
      }
      rethrow;
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    _dancingVideoController?.dispose();
    _excitedVideoController?.dispose(); // Dispose excited video controller
    _confettiController?.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    
    // Show loading if provider isn't initialized or no child selected
    if (!childProvider.isInitialized || childProvider.currentChild == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_activities.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('No brushing activities configured. Please add activities in settings.'),
        ),
      );
    }
    
    if (_currentActivityIndex >= _activities.length) {
      _currentActivityIndex = 0;
    }
    
    final activity = _activities[_currentActivityIndex];
    final totalTime = activity.duration;
    final minutes = _currentTime ~/ 60;
    final seconds = _currentTime % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Consumer2<MusicProvider, ChildProvider>(
          builder: (context, musicProvider, childProvider, _) {
            return IconButton(
              icon: Icon(
                musicProvider.isPlaying ? Icons.music_note : Icons.music_off,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                final child = childProvider.currentChild;
                if (child == null) return;
                musicProvider.playMusic(monsterId: child.monsterId);
              },
            );
          },
        ),
        title: Consumer<ChildProvider>(
          builder: (context, childProvider, _) {
            if (childProvider.currentChild != null) {
              return Text(
                childProvider.currentChild!.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.pushNamed(context, '/calendar');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () async {
              // Navigate to settings and wait for return
              await Navigator.pushNamed(context, '/settings');
              // When returning from settings, update timer if settings changed
              if (mounted) {
                _updateTimerFromSettings();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video player area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                color: Colors.transparent, // Transparent background for video area
                child: AnimatedOpacity(
                      opacity: _videoOpacity,
                      duration: const Duration(milliseconds: 300),
                      child: (!_isPlaying && _excitedVideoController != null &&
                              _excitedVideoController!.value.isInitialized)
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent, // Transparent background for webm
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: VideoPlayerWidget(controller: _excitedVideoController!),
                            )
                          : (_videoController != null &&
                                  _videoController!.value.isInitialized
                              ? VideoPlayerWidget(controller: _videoController!)
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          size: 80,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Video will appear here\nPlace videos in assets/videos/',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                    ),
              ),
            ),
            // Timer and instruction
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular timer
                      CircularTimer(
                        currentTime: _currentTime,
                        totalTime: totalTime,
                        minutes: minutes,
                        seconds: seconds,
                        totalMinutes: totalTime ~/ 60,
                      ),
                  const SizedBox(height: 30),
                  // Instruction text (use custom if available)
                  Text(
                    activity.instruction,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Control buttons
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play button
                  if (!_isPlaying)
                    GestureDetector(
                      onTap: _startTimer,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  // Pause button
                  if (_isPlaying)
                    GestureDetector(
                      onTap: _pauseTimer,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

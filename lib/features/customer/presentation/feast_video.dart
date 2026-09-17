import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The same feast film as the website, bundled for reliable mobile playback.
class FeastVideo extends StatefulWidget {
  const FeastVideo({super.key});

  @override
  State<FeastVideo> createState() => _FeastVideoState();
}

class _FeastVideoState extends State<FeastVideo> with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _visible = false;
  bool _paused = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(
      'assets/videos/sri-lankan-feast.mp4',
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      await _controller.setVolume(0);
      await _controller.setLooping(true);
      if (!mounted) return;
      setState(() => _ready = true);
      await _syncPlayback();
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  Future<void> _syncPlayback() async {
    if (!_ready || _failed) return;
    try {
      if (_visible && _foreground && !_paused) {
        await _controller.play();
      } else {
        await _controller.pause();
      }
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/sri_lankan_feast.jpg', fit: BoxFit.cover),
          if (_ready && !_failed)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (context, value, _) => value.hasError
                  ? const SizedBox.shrink()
                  : FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: value.size.width,
                        height: value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.heroOverlay],
              ),
            ),
          ),
          const Positioned(
            left: 20,
            right: 56,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A TASTE OF HOME',
                  style: TextStyle(
                    color: AppColors.heroAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Sri Lankan feast',
                  style: TextStyle(
                    color: AppColors.onImage,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Your favourites, freshly made.',
                  style: TextStyle(color: AppColors.onImage),
                ),
              ],
            ),
          ),
          if (_ready && !_failed)
            Positioned(
              right: 8,
              bottom: 12,
              child: IconButton(
                tooltip: _paused ? 'Play feast video' : 'Pause feast video',
                color: AppColors.onImage,
                onPressed: () {
                  setState(() => _paused = !_paused);
                  _syncPlayback();
                },
                icon: Icon(_paused ? Icons.play_circle : Icons.pause_circle),
              ),
            ),
        ],
      ),
    ),
  );
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isFile;
  final bool autoPlay;
  final bool loop;
  final bool showControls;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.isFile = false,
    this.autoPlay = true,
    this.loop = true,
    this.showControls = false,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.isFile 
        ? VideoPlayerController.file(File(widget.videoUrl))
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          if (widget.loop) _controller.setLooping(true);
          // Auto-play videos efficiently muted if just browsing feed
          if (widget.autoPlay && !widget.showControls) _controller.setVolume(0.0);
          if (widget.autoPlay) _controller.play();
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    });

    _controller.addListener(() {
      if (mounted && _controller.value.hasError) {
        setState(() => _hasError = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.orange),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
          ),
        ),
      );
    }

    Widget player = SizedBox(
      width: _controller.value.size.width,
      height: _controller.value.size.height,
      child: VideoPlayer(_controller),
    );

    if (widget.fit == BoxFit.cover) {
      player = ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: player,
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(child: player),
          if (widget.showControls)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: !_controller.value.isPlaying
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                          )
                        : const SizedBox(),
                  ),
                ),
              ),
            ),
          // Indicate it's a video in feed mode
          if (!widget.showControls)
            const Positioned(
              top: 8,
              left: 8,
              child: Icon(Icons.videocam, color: Colors.white, size: 24),
            ),
        ],
      ),
    );
  }
}

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_files/app.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  static String get routeName => 'video_player_page';

  final String videoUrl;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final FocusNode keyboardFocusNode = FocusNode();
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  void _init() async {
    VideoPlayerController videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    this.videoPlayerController = videoPlayerController;
    await videoPlayerController.initialize();
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      // web 端不支持 autoPlay
      autoPlay: App.isWeb ? false : true,
      fullScreenByDefault: true,
      looping: false,
      maxScale: double.infinity,
      allowedScreenSleep: false,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void dispose() {
    videoPlayerController?.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return Material(
    //   color: Colors.black,
    //   child: Center(
    //     child: SizedBox(
    //       width: MediaQuery.of(context).size.width,
    //       height: MediaQuery.of(context).size.width * 9.0 / 16.0,
    //       child: chewieController == null
    //           ? const SizedBox()
    //           : Chewie(
    //               controller: chewieController!,
    //             ),
    //     ),
    //   ),
    // );
    return KeyboardListener(
      focusNode: keyboardFocusNode,
      onKeyEvent: (keyEvent) async {
        if (keyEvent is! KeyDownEvent) {
          return;
        }
        ChewieController? controller = chewieController;
        if (controller == null) {
          return;
        }
        if (keyEvent.logicalKey == LogicalKeyboardKey.select) {
          controller.togglePause();
        } else if (keyEvent.logicalKey == LogicalKeyboardKey.arrowRight) {
          Duration? position = await controller.videoPlayerController.position;
          if (position == null) {
            return;
          }
          final newPosition = position + const Duration(seconds: 10);
          controller.seekTo(newPosition);
        } else if (keyEvent.logicalKey == LogicalKeyboardKey.arrowLeft) {
          Duration? position = await controller.videoPlayerController.position;
          if (position == null) {
            return;
          }
          final newPosition = position - const Duration(seconds: 10);
          controller.seekTo(newPosition);
        }
      },
      child: Material(
        color: Colors.black,
        child: chewieController == null
            ? const SizedBox()
            : Chewie(
                controller: chewieController!,
              ),
      ),
    );
  }
}

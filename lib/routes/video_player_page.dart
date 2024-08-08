import 'dart:math';

import 'package:chewie/chewie.dart';
import 'package:flutter/gestures.dart';
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
  final GlobalKey<ChewieState> chewieKey = GlobalKey();
  final FocusNode keyboardFocusNode = FocusNode();
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  /// 最大一次能快进/快退的时间(单位:秒)
  final int maxSeekSecond = 10 * 60;

  /// 快进/快退时间的档位
  final List<Duration> seekDuration = [
    const Duration(seconds: 10),
    const Duration(seconds: 30),
    const Duration(seconds: 60),
    const Duration(seconds: 5 * 60),
    const Duration(seconds: 10 * 60)
  ];

  /// 短时间内点击电视遥控器右键的次数
  int arrowRightCount = 0;

  /// 短时间内点击电视遥控器左键的次数
  int arrowLeftCount = 0;

  /// 上一次点击电视遥控器右键的次数
  int arrowRightTimestamp = 0;

  /// 上一次点击电视遥控器左键的次数
  int arrowLeftTimestamp = 0;

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
    return KeyboardListener(
      focusNode: keyboardFocusNode,
      onKeyEvent: (keyEvent) async {
        ChewieController? controller = chewieController;
        if (keyEvent is! KeyDownEvent || controller == null) {
          return;
        }
        if (keyEvent.logicalKey != LogicalKeyboardKey.select &&
            keyEvent.logicalKey != LogicalKeyboardKey.arrowRight &&
            keyEvent.logicalKey != LogicalKeyboardKey.arrowLeft) {
          return;
        }
        if (keyEvent.logicalKey != LogicalKeyboardKey.arrowRight) {
          arrowRightCount = 0;
          arrowRightTimestamp = 0;
        }
        if (keyEvent.logicalKey != LogicalKeyboardKey.arrowLeft) {
          arrowLeftCount = 0;
          arrowLeftTimestamp = 0;
        }
        // chewie 不支持电视, 当用户按遥控板时, 模拟用户点击, 以显示进度条
        if (chewieKey.currentState?.notifier.hideStuff == true) {
          _simulateTap();
        }
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        if (keyEvent.logicalKey == LogicalKeyboardKey.select) {
          controller.togglePause();
        } else if (keyEvent.logicalKey == LogicalKeyboardKey.arrowRight) {
          Duration? position = await controller.videoPlayerController.position;
          if (position == null) {
            return;
          }
          if (arrowRightTimestamp - timestamp < 500) {
            arrowRightCount++;
          } else {
            arrowRightCount = 1;
          }
          arrowRightTimestamp = timestamp;
          // 快进
          final newPosition = position + seekDuration[max(seekDuration.length, arrowRightCount) - 1];
          await controller.seekTo(newPosition);
        } else if (keyEvent.logicalKey == LogicalKeyboardKey.arrowLeft) {
          Duration? position = await controller.videoPlayerController.position;
          if (position == null) {
            return;
          }
          if (arrowLeftTimestamp - timestamp < 500) {
            arrowLeftCount++;
          } else {
            arrowLeftCount = 1;
          }
          arrowLeftTimestamp = timestamp;
          // 快退
          final newPosition = position - seekDuration[max(seekDuration.length, arrowLeftCount) - 1];
          await controller.seekTo(newPosition);
        }
      },
      child: Material(
        color: Colors.black,
        child: chewieController == null
            ? const SizedBox()
            : Chewie(
                key: chewieKey,
                controller: chewieController!,
              ),
      ),
    );
  }

  /// 模拟点击
  void _simulateTap() {
    final RenderBox? renderBox = chewieKey.currentContext?.findRenderObject() as RenderBox?;
    final Offset? position = renderBox?.localToGlobal(Offset.zero);
    if (renderBox != null && position != null) {
      final double centerX = position.dx + renderBox.size.width / 2;
      final double centerY = position.dy + renderBox.size.height / 2;
      final Offset center = Offset(centerX, centerY);

      final PointerDownEvent downEvent = PointerDownEvent(
        pointer: 0,
        position: center,
      );
      final PointerUpEvent upEvent = PointerUpEvent(
        pointer: 0,
        position: center,
      );

      GestureBinding.instance.handlePointerEvent(downEvent);
      GestureBinding.instance.handlePointerEvent(upEvent);
    }
  }
}

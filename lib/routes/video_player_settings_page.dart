import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/utils/snack_utils.dart';
import 'package:remote_files/widgets/loading_btn.dart';

class VideoPlayerSettingsPage extends StatefulWidget {
  static String get routeName => 'video_player_settings_page';

  const VideoPlayerSettingsPage({super.key});

  @override
  State<VideoPlayerSettingsPage> createState() => _VideoPlayerSettingsPageState();
}

class _VideoPlayerSettingsPageState extends State<VideoPlayerSettingsPage> {
  String videoPlayerPath = '';
  late Configs configs;

  @override
  void initState() {
    configs = Configs.getInstanceSync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: AppTheme.systemOverlayStyle,
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        title: const Text(
          '视频播放器设置',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      body: App.isWindows ? videoPlayerPathSetting() : mobileVideoPlayer(),
    );
  }

  Widget mobileVideoPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '使用内置播放器',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Switch(
            value: configs.useInnerPlayer,
            onChanged: (value) {
              configs.useInnerPlayer = value;
              configs.save();
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  Widget videoPlayerPathSetting() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _TextEditItem(
          required: false,
          title: '视频播放器路径',
          value: Configs.getInstanceSync().videoPlayerPath,
          textChange: (value) {
            String lastVideoPlayerPath = videoPlayerPath;
            videoPlayerPath = value;
            if (lastVideoPlayerPath.isEmpty != videoPlayerPath.isEmpty) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20),
        Container(
          height: 50,
          margin: const EdgeInsets.only(left: 16, top: 16, right: 16),
          child: LoadingBtn(
            key: Key(videoPlayerPath),
            text: '确定',
            btnStatus: videoPlayerPath.isEmpty ? BtnStatus.disable : BtnStatus.normal,
            onTap: () async {
              bool isOk = false;
              try {
                File videoPlayerFile = File(videoPlayerPath);
                if (await videoPlayerFile.exists()) {
                  isOk = true;
                }
              } catch (e) {
                isOk = false;
              }
              if (isOk) {
                Configs config = Configs.getInstanceSync();
                config.videoPlayerPath = videoPlayerPath;
                config.save();
                if (mounted) {
                  SnackUtils.showSnack(
                    context,
                    message: "已保存",
                    backgroundColor: Theme.of(context).primaryColor,
                  );
                }
              } else {
                if (mounted) {
                  SnackUtils.showSnack(
                    context,
                    message: "文件无法读取, 请确认是否选中视频播放器exe可执行文件",
                    duration: const Duration(seconds: 2),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

/// 文本修改后的监听器
typedef _TextChangeListener = void Function(
  String newText,
);

/// 文本编辑的item
class _TextEditItem extends StatefulWidget {
  final bool required;
  final String title;
  final String value;
  final _TextChangeListener textChange;

  const _TextEditItem({
    Key? key,
    required this.required,
    required this.title,
    required this.value,
    required this.textChange,
  }) : super(key: key);

  @override
  __TextEditItemState createState() => __TextEditItemState();
}

class __TextEditItemState extends State<_TextEditItem> {
  final TextEditingController _textEditingController = TextEditingController();
  FocusNode _focusNode = FocusNode();

  bool _isTextEmpty = true;
  bool _hasFocus = false;
  String _currentText = '';

  void _onTextChange(String text) {
    _currentText = text;
    widget.textChange.call(text);
    bool currentIsEmpty = text.isEmpty;
    if (currentIsEmpty != _isTextEmpty) {
      setState(() {
        _isTextEmpty = currentIsEmpty;
      });
    }
  }

  void _init() {
    _isTextEmpty = widget.value.isEmpty;
    _textEditingController.text = widget.value;
    _currentText = widget.value;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_hasFocus != _focusNode.hasFocus) {
        setState(() {
          _hasFocus = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: TextFormField(
        keyboardAppearance: Brightness.light,
        autofocus: false,
        controller: _textEditingController,
        focusNode: _focusNode,
        onChanged: _onTextChange,
        cursorColor: Theme.of(context).textSelectionTheme.cursorColor,
        cursorWidth: 1,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          labelText: widget.title,
          labelStyle: Theme.of(context).textTheme.labelMedium,
          suffixIcon: GestureDetector(
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null) {
                String path = result.files.single.path!;
                _textEditingController.text = path;
                _onTextChange(path);
              }
            },
            child: const Icon(
              Icons.more_horiz,
              size: 20,
              color: Colors.grey,
            ),
          ),
        ), //textField样式设置
      ),
    );
  }
}

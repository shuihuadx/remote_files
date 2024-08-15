import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/network/remote_files_fetcher.dart';
import 'package:remote_files/routes/remote_files_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/utils/snack_utils.dart';
import 'package:remote_files/utils/url_utils.dart';
import 'package:remote_files/widgets/loading_btn.dart';

class AddServerPage extends StatefulWidget {
  static String get routeName => 'add_server_page';

  static String get disableBackRouteName => 'add_server_page_disable_back';

  final bool enableBack;

  const AddServerPage({
    super.key,
    required this.enableBack,
  });

  @override
  State<AddServerPage> createState() => _AddServerPageState();
}

class _AddServerPageState extends State<AddServerPage> {
  String _serverName = '';
  String _serverUrl = '';
  final FocusNode keyboardFocusNode = FocusNode();

  final FocusNode backFocusNode = FocusNode();
  final FocusNode serverUrlFocusNode = FocusNode();
  final FocusNode remarkFocusNode = FocusNode();
  final FocusNode btnFocusNode = FocusNode();
  List<FocusNode> focus = [];

  int focusedIndex = -1;
  int lastClickBackTimestamp = 0;

  @override
  void initState() {
    super.initState();
    focus = widget.enableBack
        ? [
            backFocusNode,
            serverUrlFocusNode,
            remarkFocusNode,
            btnFocusNode,
          ]
        : [
            serverUrlFocusNode,
            remarkFocusNode,
            btnFocusNode,
          ];
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: keyboardFocusNode,
      onKeyEvent: (keyEvent) {
        onKeyEvent(keyEvent);
      },
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: AppTheme.systemOverlayStyle,
          backgroundColor: Theme.of(context).primaryColor,
          leading: widget.enableBack
              ? IconButton(
                  focusNode: backFocusNode,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                )
              : null,
          automaticallyImplyLeading: widget.enableBack,
          title: const Text(
            '添加服务器',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.white,
        body: PopScope(
          canPop: widget.enableBack,
          onPopInvoked: (didPop) {
            if (!didPop) {
              int timestamp = DateTime.now().millisecondsSinceEpoch;
              if (timestamp - lastClickBackTimestamp < 1000) {
                // 1秒内按两次返回将会, 退出App(此方法仅适用于Android, 也只有 Android 有此需求)
                SystemNavigator.pop();
              } else {
                lastClickBackTimestamp = timestamp;
                SnackUtils.showSnack(
                  context,
                  message: '没有上一页了，再次返回将退出应用',
                  backgroundColor: Theme.of(context).primaryColor,
                );
              }
            }
          },
          child: Column(
            children: [
              const SizedBox(height: 16),
              _TextEditItem(
                required: true,
                title: '服务器地址',
                value: '',
                focusNode: serverUrlFocusNode,
                textChange: (value) {
                  String lastServerUrl = _serverUrl;
                  _serverUrl = value.trim();
                  if (lastServerUrl.isEmpty != _serverUrl.isEmpty) {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 12),
              _TextEditItem(
                required: false,
                title: '备注',
                value: '',
                focusNode: remarkFocusNode,
                textChange: (value) {
                  _serverName = value;
                },
              ),
              const SizedBox(height: 20),
              Container(
                height: 50,
                margin: const EdgeInsets.only(left: 16, top: 16, right: 16),
                child: LoadingBtn(
                  key: Key(_serverUrl),
                  focusNode: btnFocusNode,
                  text: '确定',
                  btnStatus: _serverUrl.isEmpty ? BtnStatus.disable : BtnStatus.normal,
                  onTap: onOkClicked,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onKeyEvent(KeyEvent keyEvent) async {
    if (keyEvent is KeyDownEvent) {
      if (keyEvent.logicalKey == LogicalKeyboardKey.arrowDown ||
          keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
        FocusNode? currentFocusNode;
        FocusNode? nextFocusNode;
        if (keyEvent.logicalKey == LogicalKeyboardKey.arrowDown) {
          currentFocusNode = focusedIndex >= 0 ? focus[focusedIndex] : null;
          focusedIndex++;
          if (focusedIndex >= focus.length) {
            focusedIndex = 0;
          }
          nextFocusNode = focus[focusedIndex];
        } else if (keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
          currentFocusNode = focusedIndex >= 0 ? focus[focusedIndex] : null;
          focusedIndex--;
          if (focusedIndex < 0) {
            focusedIndex = focus.length - 1;
          }
          nextFocusNode = focus[focusedIndex];
        }
        if (currentFocusNode != null && currentFocusNode.hasFocus) {
          currentFocusNode.unfocus();
          SchedulerBinding.instance.addPostFrameCallback((_) {
            nextFocusNode?.requestFocus();
          });
        } else {
          nextFocusNode?.requestFocus();
        }
      }
    }
  }

  Widget body() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _TextEditItem(
          required: true,
          title: '服务器地址',
          value: '',
          focusNode: serverUrlFocusNode,
          textChange: (value) {
            String lastServerUrl = _serverUrl;
            _serverUrl = value.trim();
            if (lastServerUrl.isEmpty != _serverUrl.isEmpty) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 12),
        _TextEditItem(
          required: false,
          title: '备注',
          value: '',
          focusNode: remarkFocusNode,
          textChange: (value) {
            _serverName = value;
          },
        ),
        const SizedBox(height: 20),
        Container(
          height: 50,
          margin: const EdgeInsets.only(left: 16, top: 16, right: 16),
          child: LoadingBtn(
            key: Key(_serverUrl),
            focusNode: btnFocusNode,
            text: '确定',
            btnStatus: _serverUrl.isEmpty ? BtnStatus.disable : BtnStatus.normal,
            onTap: onOkClicked,
          ),
        ),
      ],
    );
  }

  Future<void> onOkClicked() async {
    // 验证是否能访问
    try {
      await remoteFilesFetcher.fetchRemoteFiles(_serverUrl);
    } catch (e) {
      // 文件服务器无法访问时, 检查网络是否正常
      bool isNetworkOk = false;
      Object? reason;
      try {
        isNetworkOk = await remoteFilesFetcher.checkNetwork();
      } catch (e2) {
        reason = e2;
      }
      if (mounted) {
        if (isNetworkOk) {
          SnackUtils.showSnack(
            context,
            message: '无法连接到文件服务器,请检查地址是否正确!reason is $e',
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          );
        } else {
          SnackUtils.showSnack(
            context,
            message: '无法访问网络,请检查网络是否正常!reason is $reason',
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          );
        }
      }
      return;
    }
    Configs configs = Configs.getInstanceSync();
    RemoteServer serverName = RemoteServer();
    serverName.serverUrl = _serverUrl;
    if (_serverName.isEmpty) {
      serverName.serverName = UrlUtils.getUrlLastPath(_serverUrl);
    } else {
      serverName.serverName = _serverName;
    }
    configs.remoteServers.add(serverName);
    if (configs.remoteServers.length == 1) {
      configs.currentServerUrl = serverName.serverUrl;
    }
    await configs.save();
    if (context.mounted) {
      if (configs.remoteServers.length == 1) {
        Navigator.of(context).pushNamed(
          RemoteFilesPage.routeName,
          arguments: configs.currentServerUrl,
        );
      } else {
        Navigator.of(context).pop(true);
      }
    }
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
  final FocusNode? focusNode;
  final _TextChangeListener textChange;

  const _TextEditItem({
    Key? key,
    required this.required,
    required this.title,
    required this.value,
    this.focusNode,
    required this.textChange,
  }) : super(key: key);

  @override
  __TextEditItemState createState() => __TextEditItemState();
}

class __TextEditItemState extends State<_TextEditItem> {
  final TextEditingController _textEditingController = TextEditingController();
  late FocusNode _focusNode;

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
    _focusNode = widget.focusNode ?? FocusNode();
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
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: TextFormField(
        keyboardAppearance: Brightness.light,
        autofocus: false,
        controller: _textEditingController,
        focusNode: _focusNode,
        onChanged: _onTextChange,
        cursorColor: Colors.grey,
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
          labelStyle: const TextStyle(color: Color(0xFF999999)),
          suffixIcon: _isTextEmpty || !_hasFocus
              ? const SizedBox()
              : GestureDetector(
                  onTap: () {
                    _textEditingController.text = '';
                    _textEditingController.selection =
                        TextSelection.fromPosition(const TextPosition(offset: 0));
                    _onTextChange('');
                  },
                  child: const Icon(
                    Icons.cancel,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
        ),
      ),
    );
  }
}

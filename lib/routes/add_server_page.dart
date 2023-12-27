import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: AppTheme.systemOverlayStyle,
        leading: widget.enableBack
            ? IconButton(
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
      body: WillPopScope(
        onWillPop: () async {
          // 拦截物理返回按钮
          if (!widget.enableBack) {
            SnackUtils.showSnack(
              context,
              message: '没有上一页了',
              backgroundColor: Theme.of(context).primaryColor,
            );
          }
          return widget.enableBack;
        },
        child: Column(
          children: [
            const SizedBox(height: 16),
            _TextEditItem(
              required: true,
              title: '服务器地址',
              value: '',
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
                color: Theme.of(context).primaryColor,
                text: '确定',
                btnStatus: _serverUrl.isEmpty ? BtnStatus.disable : BtnStatus.normal,
                borderRadius: BorderRadius.circular(4),
                onTap: () async {
                  // 验证是否能访问
                  try {
                    await remoteFilesFetcher.fetchRemoteFiles(_serverUrl);
                  } catch (e) {
                    SnackUtils.showSnack(
                      context,
                      message: '无法连接到文件服务器,请检查地址是否正确!',
                      backgroundColor: Colors.red,
                    );
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
                },
              ),
            ),
          ],
        ),
      ),
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
        ), //textField样式设置
      ),
    );
  }
}

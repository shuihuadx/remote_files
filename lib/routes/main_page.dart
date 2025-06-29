import 'package:flutter/material.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/data/file_download_manager.dart';
import 'package:remote_files/routes/add_server_page.dart';
import 'package:remote_files/routes/remote_files_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/utils/dlna_utils.dart';
import 'package:remote_files/utils/isolate_executor.dart';
import 'package:remote_files/widgets/loading_widget.dart';

const String defaultServerUrl = 'https://ipv6.agiao.baby:4433/xunlei/';
final RemoteServer defaultRemoteServer = RemoteServer()
  ..serverUrl = defaultServerUrl
  ..serverName = 'xunlei';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Future<void> _init() async {
    Configs configs = await Configs.getInstance();
    // 当 App 没有数据时, 使用默认服务器
    if (configs.remoteServers.isEmpty) {
      configs.remoteServers.add(defaultRemoteServer);
      configs.currentServerUrl = defaultServerUrl;
      await configs.save();
    }
    AppTheme.themeModel.setThemeData(AppTheme.createThemeDataByColor(Color(configs.themeColor)));

    await isolateExecutor.init();
    await fileDownloadManager.init();

    bool enableDlnaPlay = !App.isWeb;
    if (await App.isAndroidTv()) {
      enableDlnaPlay = false;
    }
    if (enableDlnaPlay) {
      DlnaUtils.startSearch();
    }

    if (mounted) {
      if (configs.remoteServers.isEmpty) {
        // 还没有服务器配置信息, 跳转到添加服务器页面
        Navigator.of(context).pushNamed(AddServerPage.disableBackRouteName);
      } else {
        // 跳转到文件列表
        Navigator.of(context).pushNamed(
          RemoteFilesPage.routeName,
          arguments: configs.currentServerUrl,
        );
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const LoadingWidget(
        width: 100,
        height: 100,
      ),
    );
  }
}

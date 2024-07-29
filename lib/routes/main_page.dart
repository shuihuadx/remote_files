import 'package:flutter/material.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/routes/add_server_page.dart';
import 'package:remote_files/routes/remote_files_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/widgets/loading_widget.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    Configs.getInstance().then((configs) {
      AppTheme.themeModel.setThemeData(AppTheme.createThemeDataByColor(Color(configs.themeColor)));
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
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const LoadingWidget(
        width: 100,
        height: 100,
      ),
    );
  }
}

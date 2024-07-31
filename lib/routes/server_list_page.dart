import 'package:flutter/material.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/routes/add_server_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/utils/snack_utils.dart';
import 'package:remote_files/widgets/loading_btn.dart';

class ServerListPage extends StatefulWidget {
  static String get routeName => 'server_list_page';

  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  late List<RemoteServer> remoteServers;
  late String currentServerUrl;

  @override
  void initState() {
    super.initState();
    remoteServers = Configs.getInstanceSync().remoteServers;
    currentServerUrl = Configs.getInstanceSync().currentServerUrl;
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
          '服务器管理',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      body: ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          if (index == remoteServers.length) {
            return addServerButton();
          }
          String serverUrl = remoteServers[index].serverUrl;
          return Container(
            padding: const EdgeInsets.only(right: 12),
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: currentServerUrl == serverUrl
                        ? Theme.of(context).unselectedWidgetColor
                        : Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    if (currentServerUrl == serverUrl) {
                      SnackUtils.showSnack(
                        context,
                        message: '当前服务正在使用,不能删除',
                        backgroundColor: Theme.of(context).primaryColor,
                      );
                    } else {
                      Configs configs = Configs.getInstanceSync();
                      configs.remoteServers.removeAt(index);
                      setState(() {
                        remoteServers = configs.remoteServers;
                        currentServerUrl = configs.currentServerUrl;
                      });
                      configs.save();
                    }
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (serverUrl != currentServerUrl) {
                        Configs configs = Configs.getInstanceSync();
                        configs.currentServerUrl = serverUrl;
                        setState(() {
                          currentServerUrl = serverUrl;
                        });
                        configs.save();
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            remoteServers[index].serverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff333333),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            serverUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff999999),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                currentServerUrl == remoteServers[index].serverUrl
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      )
                    : const SizedBox(),
              ],
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            color: Color(0xFFE5E5E5),
            indent: 1,
            height: 0,
          );
        },
        itemCount: remoteServers.length + 1,
      ),
    );
  }

  Widget addServerButton() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(left: 16, top: 30, right: 16),
      child: LoadingBtn(
        text: '添加服务器',
        textFontSize: 16,
        btnStatus: BtnStatus.normal,
        onTap: () {
          Navigator.of(context).pushNamed(AddServerPage.routeName).then((value) {
            if (value == true) {
              setState(() {});
            }
          });
        },
      ),
    );
  }
}

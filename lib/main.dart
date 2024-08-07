import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/routes/add_server_page.dart';
import 'package:remote_files/routes/main_page.dart';
import 'package:remote_files/routes/remote_files_page.dart';
import 'package:remote_files/routes/server_list_page.dart';
import 'package:remote_files/routes/theme_color_settings_page.dart';
import 'package:remote_files/routes/video_player_page.dart';
import 'package:remote_files/routes/video_player_settings_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/theme/theme_model.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (App.isWindows || App.isLinux || App.isMacOS) {
    // 必须加上这一行。
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeModel>(
          create: (context) => AppTheme.themeModel,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: App.navigatorKey,
      title: 'RemoteFiles',
      theme: Provider.of<ThemeModel>(context).themeData,
      routes: {
        AddServerPage.routeName: (context) => const AddServerPage(enableBack: true),
        AddServerPage.disableBackRouteName: (context) => const AddServerPage(enableBack: false),
        ThemeColorSettingsPage.routeName: (context) => const ThemeColorSettingsPage(),
        VideoPlayerSettingsPage.routeName: (context) => const VideoPlayerSettingsPage(),
        ServerListPage.routeName: (context) => const ServerListPage(),
        '/': (context) => const MainPage(),
      },
      onGenerateRoute: (RouteSettings settings) {
        String routeName = settings.name ?? '';
        if (routeName == RemoteFilesPage.routeName) {
          return MaterialPageRoute(
            builder: (context) {
              return RemoteFilesPage(
                url: settings.arguments as String,
              );
            },
            settings: settings,
          );
        } else if (routeName == VideoPlayerPage.routeName) {
          return MaterialPageRoute(
            builder: (context) {
              return VideoPlayerPage(
                videoUrl: settings.arguments as String,
              );
            },
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/theme/app_theme.dart';

const List<Color> themeColors = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
];

class ThemeColorSettingsPage extends StatefulWidget {
  static String get routeName => 'theme_color_settings_page';

  const ThemeColorSettingsPage({super.key});

  @override
  State<ThemeColorSettingsPage> createState() => _ThemeColorSettingsPageState();
}

class _ThemeColorSettingsPageState extends State<ThemeColorSettingsPage> {
  late int _themeColor;
  late int _selectedIndex;

  @override
  void initState() {
    _themeColor = Configs.getInstanceSync().themeColor;
    _selectedIndex = themeColors.indexWhere((color) => color.value == _themeColor);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          '主题颜色设置',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: GridView.builder(
        itemCount: themeColors.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, //每行6列
          childAspectRatio: 1.0, //显示区域宽高相等
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            child: Container(
              color: themeColors[index],
              child: _selectedIndex == index
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                    )
                  : null,
            ),
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _themeColor = themeColors[index].value;
              });
              AppTheme.themeModel.setThemeData(ThemeData(
                primarySwatch: AppTheme.createMaterialColor(themeColors[index]),
              ));
              Configs configs = Configs.getInstanceSync();
              configs.themeColor = _themeColor;
              configs.save();
            },
          );
        },
      ),
    );
  }
}

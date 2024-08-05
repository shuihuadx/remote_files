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

  int _focusedIndex = -1;

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
          '主题颜色设置',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GridView.builder(
              itemCount: themeColors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, //每行6列
                childAspectRatio: 1.0, //显示区域宽高相等
              ),
              itemBuilder: (context, index) {
                return ElevatedButton(
                  style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      shape: WidgetStateProperty.all(const LinearBorder()),
                      elevation: WidgetStateProperty.all(_focusedIndex == index ? 1 : 0)),
                  onFocusChange: (hasFocused) {
                    if (hasFocused) {
                      if (_focusedIndex != index) {
                        setState(() {
                          _focusedIndex = index;
                        });
                      }
                    }
                  },
                  onPressed: () {
                    setState(() {
                      _selectedIndex = index;
                      _themeColor = themeColors[index].value;
                    });
                    AppTheme.themeModel
                        .setThemeData(AppTheme.createThemeDataByColor(themeColors[index]));
                    Configs configs = Configs.getInstanceSync();
                    configs.themeColor = _themeColor;
                    configs.save();
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: themeColors[index],
                    child: _selectedIndex == index
                        ? const Icon(
                      Icons.check,
                      color: Colors.white,
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: GridView.builder(
                itemCount: themeColors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, //每行6列
                  childAspectRatio: 1.0, //显示区域宽高相等
                  mainAxisSpacing: 4.0, // 设置主轴方向的间距
                  crossAxisSpacing: 4.0, // 设置交叉轴方向的间距
                ),
                itemBuilder: (context, index) {
                  bool isFocused = _focusedIndex == index;
                  return AnimatedScale(
                    scale: 1.2,
                    duration: const Duration(milliseconds: 200),
                    child: isFocused
                        ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: themeColors[index],
                      child: _selectedIndex == index
                          ? const Icon(
                        Icons.check,
                        color: Colors.white,
                      )
                          : null,
                    )
                        : Container(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

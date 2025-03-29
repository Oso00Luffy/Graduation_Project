import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart'; // Import the routes configuration
import 'screens/home_screen.dart'; // Import HomeScreen
import 'screens/settings_screen.dart'; // Import SettingsScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = (prefs.getBool('isDarkMode') ?? false);
    });
  }

  _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('isDarkMode', value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCC - Secure - Chat - Crypt',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      routes: appRoutes,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (context) {
            switch (settings.name) {
              case '/':
                return HomeScreen(
                  isDarkMode: args['isDarkMode'] ?? _isDarkMode,
                  toggleTheme: args['toggleTheme'] ?? _toggleTheme,
                );
              case '/settings':
                return SettingsScreen(
                  isDarkMode: args['isDarkMode'] ?? _isDarkMode,
                  toggleTheme: args['toggleTheme'] ?? _toggleTheme,
                );
              default:
                return Scaffold(
                  body: Center(
                    child: Text('No route defined for ${settings.name}'),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
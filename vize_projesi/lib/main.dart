import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller/user_controller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'model/user_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // plugin'in başlatılması
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  static bool changeLanguage(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setState(() {
      state._locale = newLocale;
      state._themeMode =
          newLocale.languageCode == 'en' ? ThemeMode.light : ThemeMode.dark;
    });
    return true;
  }
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en', 'US'); // Varsayılan dil ayarı

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale, // MaterialApp içinde dil ayarı
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('tr', 'TR'),
      ],
      themeMode: _themeMode,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: HomePage(toggleTheme: _toggleTheme),
    );
  }
}

class HomePage extends ConsumerWidget {
  final VoidCallback toggleTheme;

  HomePage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final container = ProviderContainer();
    final allUsersFuture = container.read(UserController.future);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("UserList"),
          actions: [
            IconButton(
              onPressed: toggleTheme,
              icon: const Icon(Icons.brightness_2_outlined),
            ),
            IconButton(
              onPressed: () {
                MyApp.changeLanguage(context, const Locale('en', 'US'));
              },
              icon: const Icon(Icons.language),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Users'),
              Tab(text: 'Saved Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserListTab(context, allUsersFuture, ref),
            _buildSavedUsersTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListTab(BuildContext context,
      Future<List<UserModel>> allUsersFuture, WidgetRef ref) {
    return FutureBuilder<List<UserModel>>(
      future: allUsersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<UserModel> users = snapshot.data ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              UserModel user = users[index];
              return ListTile(
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text('${user.email}'),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    user.avatar.toString(),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    _saveUser(context, user);
                    // Kaydedilen Kullanıcılar sekmesine geçiş
                    DefaultTabController.of(context).animateTo(1);
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildSavedUsersTab(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _getSavedUsers(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<UserModel> savedUsers = snapshot.data ?? [];
          return savedUsers.isEmpty
              ? const Center(
                  child: Text('No saved users.'),
                )
              : ListView.builder(
                  itemCount: savedUsers.length,
                  itemBuilder: (context, index) {
                    UserModel user = savedUsers[index];
                    return ListTile(
                      title: Text(
                        '${user.firstName} ${user.lastName}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText1!.color,
                        ),
                      ),
                      subtitle: Text(
                        '${user.email}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2!.color,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          user.avatar.toString(),
                        ),
                      ),
                      tileColor: Theme.of(context).cardColor,
                    );
                  },
                );
        }
      },
    );
  }

  Future<List<UserModel>> _getSavedUsers(BuildContext context) async {
    final container = ProviderContainer();
    final allUsers = await container.read(UserController.future);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedUsers = prefs.getStringList('saved_users');

    if (savedUsers != null) {
      List<UserModel> savedUsersList = [];

      for (UserModel user in allUsers) {
        if (savedUsers.contains(user.toJson().toString())) {
          savedUsersList.add(user);
        }
      }

      return savedUsersList;
    } else {
      return [];
    }
  }

  Future<void> _saveUser(BuildContext context, UserModel user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedUsers = prefs.getStringList('saved_users') ?? [];

    // Kullanıcının zaten kaydedilip kaydedilmediğini kontrol edin
    if (!savedUsers.contains(user.toJson().toString())) {
      savedUsers.add(user.toJson().toString());
      await prefs.setStringList('saved_users', savedUsers);

      // Kaydedilen kullanıcıya bildirim göster
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'User Saved Successfully !',
        '${user.firstName} ${user.lastName}',
        platformChannelSpecifics,
      );

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.firstName} ${user.lastName} saved.'),
        ),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${user.firstName} ${user.lastName} is already saved.'),
        ),
      );
    }
  }
}

 import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller/user_controller.dart';
import 'model/user_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en', 'US'), Locale('tr', 'TR')],
      path: 'assets/translations', // çeviri dosyalarının bulunduğu klasör
      fallbackLocale: Locale('en', 'US'), // varsayılan dil
      child: ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

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
      themeMode: _themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: HomePage(toggleTheme: _toggleTheme,),
    );
  }
}

class HomePage extends ConsumerWidget {
  final VoidCallback toggleTheme;
   void _toggleLanguage(BuildContext context){
    if(context.locale == Locale('en', 'US')){
     context.setLocale(Locale('tr', 'TR'));
    }
    else{
      context.setLocale(Locale('en', 'US'));
    }
  }

  HomePage({Key? key, required this.toggleTheme,}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final container = ProviderContainer();
    final allUsersFuture = container.read(UserController.future);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('User List'.tr()), 
          actions: [
            IconButton(
              onPressed: toggleTheme,
              icon: const Icon(Icons.brightness_2_outlined),
            ),
            IconButton(
              onPressed: () {
                _toggleLanguage(context);
              },
              icon: const Icon(Icons.language),
            ),
          ],
          bottom:  TabBar(
            tabs: [
              Tab(text: 'All Users'.tr()),
              Tab(text: 'Saved Users'.tr()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${user.firstName} ${user.lastName} Saved"),
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
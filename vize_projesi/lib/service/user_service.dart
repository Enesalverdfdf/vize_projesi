import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';

class UserService {
  String userUrl = 'https://reqres.in/api/users?page=2';

 Future<List<UserModel>> getUsers() async {
    Response response = await get(Uri.parse(userUrl));
    if (response.statusCode == 200) {
      final List result = jsonDecode(response.body)['data'];
      return result.map((e) => UserModel.fromJson(e)).toList();
    } else {
      throw Exception(response.reasonPhrase);
    }
  }
  Future<void> saveUser(UserModel user) async{
   final prefs= await SharedPreferences.getInstance();
   final List<String> savedUsers=prefs.getStringList('saved_users')?? [];
   savedUsers.add(json.encode(user.toJson()));
   await prefs.setStringList('saved_users', savedUsers);
   user.isSaved = true;
  }

   Future<List<UserModel>> loadSavedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedUsersJson = prefs.getStringList('saved_users') ?? [];
    return savedUsersJson.map((savedUserJson) => UserModel.fromJson(json.decode(savedUserJson))).toList();
  }
  
}
final userController=Provider<UserService>((ref)=>UserService());
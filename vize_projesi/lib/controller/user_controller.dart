import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/user_model.dart';
import '../service/user_service.dart';

final userControllerProvider = Provider<UserService>((ref) {
  return UserService();
});

final UserController = FutureProvider<List<UserModel>>((ref) async {
  final userService = ref.watch(userControllerProvider);
  return userService.getUsers();
});
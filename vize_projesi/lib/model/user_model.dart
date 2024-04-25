
class UserModel {
  int? id;
  String? email;
  String? firstName;
  String? lastName;
  String? avatar;
  bool? isSaved;

  UserModel({this.id, this.email, this.firstName, this.lastName,this.avatar,this.isSaved=false});

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    avatar = json['avatar'];
  }
  Map<String,dynamic> toJson(){
    return{
      'id':id,
      'email':email,
      'firstName':firstName,
      'lastName':lastName,
      'avatar':avatar
    };
  }
}

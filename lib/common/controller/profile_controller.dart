import 'package:flayr/common/controller/base_controller.dart';
import 'package:flayr/model/user_model/user_model.dart';

class ProfileController extends BaseController {
  User? user;

  ProfileController(this.user);

  updateUser(User? user) {
    this.user = user;
  }
}

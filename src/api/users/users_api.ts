import { LoginRequest } from "../../models/users/users_model";
import { userService } from "../../services/users/users_service"

class UserApi {

    getUsers() {
        let user_service = new userService()
        let users = user_service.getUserService()
        return users;
    }

    userLogin(params:LoginRequest) {
        let user_service = new userService()
        return user_service.userLoginService(params)
    }
}

export {
    UserApi
}
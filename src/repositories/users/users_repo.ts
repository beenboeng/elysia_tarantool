import { LoginRequest } from "../../models/users/users_model"

class UserRepo {

    getUsers() {
        return "hi from uesrs repo"
    }

    userLoginRepo(params: LoginRequest) {
        return params
    }
}

export {
    UserRepo
}
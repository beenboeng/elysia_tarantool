import { LoginRequest } from "../../models/users/users_model";
import { UserRepo } from "../../repositories/users/users_repo"

class userService {
    getUserService() {
        let userRepo = new UserRepo()
        let userData = userRepo.getUsers()
        return userData;
    }

    userLoginService(params:LoginRequest) {
        let userRepo = new UserRepo()
        return userRepo.userLoginRepo(params)

    }
}

export { userService }
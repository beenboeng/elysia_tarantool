import { Elysia } from "elysia";
import { UserApi } from "../api/users/users_api";
import { user } from "../models/users/users_model";


const userApi = new UserApi();

const app = new Elysia().group("/api/v1", (app) => app

  // model 
  .model(user)
  //

  // module users 
  .group("users", (app) => app
    .get("", userApi.getUsers)

    .post("login", ({ body }) => {
      
      return userApi.userLogin(body)
    }, {
      body: 'login'
    })
  )

  // module bets 
  .group("bets", (app) => app
    .get("", userApi.getUsers)
  )

)

export default app;



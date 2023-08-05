import { t } from "elysia";

const user = {
    "login": t.Object({
        username: t.String(),
        password: t.String(),
        secret: t.Number()
    }),
}

interface LoginRequest {
    username: string,
    password: string,
    secret: number,
}

export {
    user,
    LoginRequest
}
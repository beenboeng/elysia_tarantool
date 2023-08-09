import { Elysia } from "elysia";
import TarantoolConnection from 'tarantool-driver';


//Decal Database Tarantool Connection
let conn = new TarantoolConnection({
  host: 'localhost',
  port: 3333,
  username: 'user01',
  password: 'user0123',
  beforeReserve: 1,
});

export {
    conn,
}
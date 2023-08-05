import { Elysia } from "elysia";
import TarantoolConnection from 'tarantool-driver';


//Decal Database Tarantool Connection
let conn = new TarantoolConnection({
  host: 'localhost',
  port: 3333,
  username: 'benz',
  password: '123456',
  beforeReserve: 1,
});

export {
    conn,
}
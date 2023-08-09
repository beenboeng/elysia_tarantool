#! /usr/bin/tarantool


-- This is default tarantool initialization file
-- with easy to use configuration examples including
-- replication, sharding and all major features
-- Complete documentation available in:  http://tarantool.org/doc/
--
-- To start this instance please run `systemctl start tarantool@example` or
-- use init scripts provided by binary packages.
-- To connect to the instance, use "sudo tarantoolctl enter example"
-- Features:
-- 1. Database configuration
-- 2. Binary logging and snapshots
-- 3. Replication
-- 4. Automatinc sharding
-- 5. Message queue
-- 6. Data expiration
-----------------
-- Configuration
-----------------
box.cfg {
    ------------------------
    -- Network configuration
    ------------------------

    -- The read/write data port number or URI
    -- Has no default value, so must be specified if
    -- connections will occur from remote clients
    -- that do not use “admin address”
    listen = 3333,
    -- listen = '*:3301';

    -- The server is considered to be a Tarantool replica
    -- it will try to connect to the master
    -- which replication_source specifies with a URI
    -- for example konstantin:secret_password@tarantool.org:3301
    -- by default username is "guest"
    -- replication_source="127.0.0.1:3102";

    -- The server will sleep for io_collect_interval seconds
    -- between iterations of the event loop
    io_collect_interval = nil,

    -- The size of the read-ahead buffer associated with a client connection
    readahead = 16320,

    ----------------------
    -- Memtx configuration
    ----------------------

    -- An absolute path to directory where snapshot (.snap) files are stored.
    -- If not specified, defaults to /var/lib/tarantool/INSTANCE
    -- memtx_dir = nil;

    -- How much memory Memtx engine allocates
    -- to actually store tuples, in bytes.
    memtx_memory = 128 * 1024 * 1024,

    -- Size of the smallest allocation unit, in bytes.
    -- It can be tuned up if most of the tuples are not so small
    memtx_min_tuple_size = 16,

    -- Size of the largest allocation unit, in bytes.
    -- It can be tuned up if it is necessary to store large tuples
    memtx_max_tuple_size = 10 * 1024 * 1024, -- 10Mb
    vinyl_max_tuple_size = 10 * 1024 * 1024, -- 10Mb

    ----------------------
    -- Vinyl configuration
    ----------------------

    -- An absolute path to directory where Vinyl files are stored.
    -- If not specified, defaults to /var/lib/tarantool/INSTANCE
    -- vinyl_dir = nil;

    -- How much memory Vinyl engine can use for in-memory level, in bytes.
    vinyl_memory = 128 * 1024 * 1024, -- 128 mb

    -- How much memory Vinyl engine can use for caches, in bytes.
    vinyl_cache = 64 * 1024 * 1024, -- 64 mb

    -- The maximum number of background workers for compaction.
    vinyl_write_threads = 2,

    ------------------------------
    -- Binary logging and recovery
    ------------------------------

    -- An absolute path to directory where write-ahead log (.xlog) files are
    -- stored. If not specified, defaults to /var/lib/tarantool/INSTANCE
    -- wal_dir = nil;

    -- Specify fiber-WAL-disk synchronization mode as:
    -- "none": write-ahead log is not maintained;
    -- "write": fibers wait for their data to be written to the write-ahead log;
    -- "fsync": fibers wait for their data, fsync follows each write;
    --    wal_mode = "none";
    wal_mode = "write",

    -- The maximal size of a single write-ahead log file
    wal_max_size = 256 * 1024 * 1024,

    -- The interval between actions by the snapshot daemon, in seconds
    checkpoint_interval = 60 * 60, -- one hour

    -- The maximum number of snapshots that the snapshot daemon maintans
    checkpoint_count = 6,

    -- Reduce the throttling effect of box.snapshot() on
    -- INSERT/UPDATE/DELETE performance by setting a limit
    -- on how many megabytes per second it can write to disk
    snap_io_rate_limit = nil,

    -- Don't abort recovery if there is an error while reading
    -- files from the disk at server start.
    force_recovery = true,

    ----------
    -- Logging
    ----------

    -- How verbose the logging is. There are six log verbosity classes:
    -- 1 – SYSERROR
    -- 2 – ERROR
    -- 3 – CRITICAL
    -- 4 – WARNING
    -- 5 – INFO
    -- 6 – DEBUG
    log_level = 5,
    -- log = "tarantool.log";

    -- By default, the log is sent to /var/log/tarantool/INSTANCE.log
    -- If logger is specified, the log is sent to the file named in the string
    --     log = "tarantool.log",
    --     wal_dir = './db/wal',
    --     memtx_dir = './db/memtx',
    --     vinyl_dir = './db/vinyl',
    -- work_dir = './work',

    -- If true, tarantool does not block on the log file descriptor
    -- when it’s not ready for write, and drops the message instead
    -- log_nonblock = true;

    -- If processing a request takes longer than
    -- the given value (in seconds), warn about it in the log
    too_long_threshold = 0.5,

    -- Inject the given string into server process title
    -- custom_proc_title = 'example';
    background = false
    -- pid_file = 'rust.pid';
}

local function bootstrap()
    --     box.schema.user.grant('guest', 'read,write,execute', 'universe')

    box.schema.user.create('user01', {
        password = 'user0123'
    })
    box.schema.user.grant('user01', 'read,write,execute,create,alter,drop', 'universe')
end
box.once('grants2', bootstrap)

json = require('json')
fiber = require('fiber')
uuid = require("uuid")
datetime = require("datetime")
decimal = require('decimal')
console = require("console")
log = require('log')

local function init_coins_space()
    local coinsSpace = box.space.coins_space
    local seq_coin_id = box.sequence.seq_coin_id
  
    if coinsSpace == nil then
      if seq_coin_id ~= nil then
        seq_coin_id:drop()
      end
  
      box.schema.sequence.create('seq_coin_id', { start = 1 })
  
      local format = {
        {"id", "unsigned"},
        {"coin_uuid", "uuid", is_nullable = false},
        {"coin_id", "number", is_nullable = true},
        {"group_id", "number", is_nullable = true},
        {"currency_id", "number", is_nullable = false},
        {"label", "string", is_nullable = false},
        {"value", "number", is_nullable = false},
        {"color_code", "string", is_nullable = true},
  
        {"created_at", "datetime", is_nullable = true},
        {"created_by", "number", is_nullable = true},
        {"updated_at", "datetime", is_nullable = true},
        {"updated_by", "number", is_nullable = true},
        {"deleted_at", "datetime", is_nullable = true},
        {"deleted_by", "number", is_nullable = true},
        {"is_active", "boolean", is_nullable = false, default="true"},
        {"order", "number", is_nullable = true, default="1"},
        {"coin_asset_id", "number", is_nullable=true} -- from coin_assets_space, field id
      }
  
    coinsSpace = box.schema.create_space('coins_space', { format = format, id = 1002 })
  
    coinsSpace:create_index('id', {
        parts = { { 'id', 'unsigned' } },
        sequence = 'seq_coin_id',
        if_not_exists = true
      })
    --   coinsSpace:create_index('coin_uuid_currency_id_coin_asset_id',
    --     {
    --       parts = { { 'coin_uuid', 'uuid' }, { 'currency_id', 'number' }, { 'coin_asset_id', 'number' } },
    --       if_not_exists = true,
    --       unique = false
    --     }
    --   )
  
    end
  
    -- sample data for testing 

    if coinsSpace:len() == 0 then
        -- Insert default records
      coinsSpace:auto_increment{uuid.fromstr('962c908e-70b8-4e5a-8786-d23de7b8ed6f'), 1, 1, 1, '១ពាន់', 1000, 'blue', datetime.parse('2023-05-28T17:20:30.301612345Z'), 1, nil, nil, nil, nil, true, 1, 1}
      coinsSpace:auto_increment{uuid.fromstr('3783ff01-0732-4094-b2fc-e4b33854c80d'), 2, 1, 1, '៥ពាន់', 5000, 'green', datetime.parse('2023-05-28T17:21:51.798111345Z'), 1, nil, nil, nil, nil, true, 1, 2}
      coinsSpace:auto_increment{uuid.fromstr('99241ae8-cb4f-42c9-8890-320bdf98bd4e'), 3, 1, 1, '២មុឺន', 20000, 'brown', datetime.parse('2023-05-28T17:22:45.716791831Z'), 1, nil, nil, nil, nil, true, 1, 3}
      coinsSpace:auto_increment{uuid.fromstr('71a3f6f0-7daf-450b-8354-a08853a1f63e'), 4, 1, 1, '៥មុឺន', 50000, 'yellow', datetime.parse('2023-05-28T17:23:25.692623639Z'), 1, nil, nil, nil, nil, true, 1, 4}
      coinsSpace:auto_increment{uuid.fromstr('8e489b33-2e45-41b6-b96f-1681c7273bd8'), 5, 1, 1, '២0មុឺន', 200000, 'dark-red', datetime.parse('2023-05-28T17:24:04.886882506Z'), 1, nil, nil, nil, nil, true, 1, 5}
      coinsSpace:auto_increment{uuid.fromstr('b7753b00-c3a0-4a37-85b5-57bc735d4a19'), 6, 1, 1, '៥0មុឺន', 500000, 'light-blue', datetime.parse('2023-05-28T17:24:40.479083523Z'), 1, nil, nil, nil, nil, true, 1, 6}
    end

    -- 
  end


--   run this function to create space
  init_coins_space()
--   

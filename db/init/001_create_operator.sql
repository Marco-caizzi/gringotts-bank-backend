CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username      TEXT NOT NULL UNIQUE CHECK (username ~ '^[A-Za-z0-9]+$'),
    role          TEXT NOT NULL CHECK (role IN ('supervisor','subordinado')),
    profile_photo TEXT NOT NULL
);

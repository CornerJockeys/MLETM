-- Local-only stand-in for the real Sprocket database.
-- Sprocket is a separate system this bot reads from via cross-schema joins.
-- It is not something this repo provisions in production. These empty tables
-- exist only so the existing migrations/services run against PGlite without
-- a live Sprocket link. Every Sprocket lookup naturally returns no rows here,
-- which is exactly what drives the MLETM identity fallback.
CREATE SCHEMA IF NOT EXISTS sprocket;

CREATE TABLE IF NOT EXISTS sprocket."user" (
  id SERIAL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS sprocket.user_authentication_account (
  id SERIAL PRIMARY KEY,
  "userId" INTEGER NOT NULL REFERENCES sprocket."user"(id),
  "accountType" VARCHAR(50) NOT NULL,
  "accountId" VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS sprocket.member (
  id SERIAL PRIMARY KEY,
  "userId" INTEGER NOT NULL REFERENCES sprocket."user"(id)
);

CREATE TABLE IF NOT EXISTS sprocket.game (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS sprocket.game_skill_group (
  id SERIAL PRIMARY KEY,
  "gameId" INTEGER NOT NULL REFERENCES sprocket.game(id)
);

CREATE TABLE IF NOT EXISTS sprocket.game_skill_group_profile (
  id SERIAL PRIMARY KEY,
  "skillGroupId" INTEGER NOT NULL REFERENCES sprocket.game_skill_group(id),
  code VARCHAR(50),
  description VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS sprocket.player (
  id SERIAL PRIMARY KEY,
  "memberId" INTEGER NOT NULL REFERENCES sprocket.member(id),
  "skillGroupId" INTEGER NOT NULL REFERENCES sprocket.game_skill_group(id)
);

CREATE TABLE IF NOT EXISTS sprocket.member_platform_account (
  id SERIAL PRIMARY KEY,
  "memberId" INTEGER NOT NULL REFERENCES sprocket.member(id),
  "platformAccountId" VARCHAR(255)
);

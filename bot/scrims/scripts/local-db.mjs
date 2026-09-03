#!/usr/bin/env node
// Temporary local Postgres substitute for testers who don't have a hosted
// database yet. Runs PGlite (an embedded Postgres) and exposes it over the
// normal Postgres wire protocol so DATABASE_URL / the existing `pg` code path
// (schema.sql, migrations, all services) works completely unmodified.
//
// Data is persisted under bot/scrims/.localdb/pgdata (gitignored). Delete
// that folder to reset the local database.
//
// Usage: npm run db:local
// This script is local development tooling only; production still uses DATABASE_URL.
import { existsSync, mkdirSync, readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { PGlite } from '@electric-sql/pglite';
import { PGLiteSocketServer } from '@electric-sql/pglite-socket';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const dataDir = path.join(projectRoot, '.localdb', 'pgdata');
const dbDir = path.join(projectRoot, 'db');

const host = process.env.LOCAL_DB_HOST || '127.0.0.1';
const port = Number(process.env.LOCAL_DB_PORT || 55432);
const loadSeedData = process.env.LOCAL_DB_SEED === 'true';

function readSql(relativePath) {
  return readFileSync(path.join(dbDir, relativePath), 'utf8');
}

async function bootstrapIfEmpty(db, isFreshDatabase) {
  if (!isFreshDatabase) {
    console.log(`[local-db] Reusing existing data directory: ${dataDir}`);
    return;
  }

  console.log('[local-db] Fresh data directory detected, applying schema + migrations...');
  await db.exec(readSql('schema.sql'));

  console.log('[local-db] Applying local Sprocket stub schema (empty tables; drives the MLETM fallback)...');
  await db.exec(readFileSync(path.join(projectRoot, 'scripts', 'local-sprocket-stub.sql'), 'utf8'));

  const migrationsDir = path.join(dbDir, 'migrations');
  const migrationFiles = readdirSync(migrationsDir)
    .filter((file) => file.endsWith('.sql'))
    .sort();

  for (const file of migrationFiles) {
    console.log(`[local-db] Applying migration: ${file}`);
    await db.exec(readSql(path.join('migrations', file)));
  }

  if (loadSeedData) {
    console.log('[local-db] Loading seed data (LOCAL_DB_SEED=true)...');
    await db.exec(readSql('seed.sql'));
  }

  console.log('[local-db] Bootstrap complete.');
}

async function main() {
  mkdirSync(path.dirname(dataDir), { recursive: true });
  const isFreshDatabase = !existsSync(path.join(dataDir, 'PG_VERSION'));
  const db = await PGlite.create(dataDir);
  await bootstrapIfEmpty(db, isFreshDatabase);

  const server = new PGLiteSocketServer({ db, host, port });
  await server.start();

  console.log(`[local-db] PGlite Postgres server listening on postgresql://${host}:${port}`);
  console.log('[local-db] Point DATABASE_URL at this, e.g.:');
  console.log(`[local-db]   DATABASE_URL=postgresql://postgres:postgres@${host}:${port}/postgres`);

  let shuttingDown = false;
  const shutdown = async () => {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log('\n[local-db] Shutting down...');
    await server.stop();
    await db.close();
    process.exit(0);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);

  // Some pglite-socket versions do not keep Node's event loop referenced even
  // after start() resolves. Hold the process open explicitly so the TCP server
  // remains available until SIGINT/SIGTERM triggers the shutdown handler.
  await new Promise(() => {});
}

main().catch((error) => {
  console.error('[local-db] Fatal error:', error);
  process.exit(1);
});

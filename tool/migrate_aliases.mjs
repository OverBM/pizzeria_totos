#!/usr/bin/env node
/**
 * Migra aliases de acceso para usuarios existentes.
 *
 * Uso:
 *   cd tool
 *   node migrate_aliases.mjs --credentials ../ruta/service-account.json
 *   node migrate_aliases.mjs --dry-run
 *
 * Requiere `firebase-admin` (ya está en tool/package.json).
 */
import { existsSync, readFileSync } from 'node:fs';
import { basename, dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..');
const DATA = join(ROOT, 'assets', 'data', 'reserved_aliases.json');

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const credentialsArg = valueAfter('--credentials') ?? process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!credentialsArg) {
  fail('Falta --credentials o GOOGLE_APPLICATION_CREDENTIALS.');
}
const credentialsPath = isAbsolute(credentialsArg)
  ? credentialsArg
  : resolve(ROOT, credentialsArg);
if (!existsSync(credentialsPath)) {
  fail(`No existe la credencial: ${credentialsPath}`);
}

const app = initializeApp({ credential: cert(readJson(credentialsPath)) });
const auth = getAuth(app);
const db = getFirestore(app);
const reserved = readJson(DATA);
const reservedWords = new Set(
  Object.values(reserved.reserved ?? {}).flat().map(normalize),
);

let pageToken;
let migrated = 0;
let skipped = 0;

do {
  const page = await auth.listUsers(1000, pageToken);
  for (const user of page.users) {
    const profileRef = db.collection('usuarios').doc(user.uid);
    const profile = await profileRef.get();
    const currentAlias = profile.data()?.usuario;
    if (currentAlias) {
      const aliasDoc = await db.collection('aliases').doc(currentAlias).get();
      if (aliasDoc.exists && aliasDoc.data()?.uid === user.uid) {
        skipped += 1;
        continue;
      }
    }
    const email = user.email ?? '';
    if (!email) {
      skipped += 1;
      continue;
    }
    const alias = await uniqueAlias(suggest(email), user.uid);
    if (!alias) {
      skipped += 1;
      continue;
    }
    console.log(`${dryRun ? '[dry] ' : ''}${email} -> ${alias}`);
    if (!dryRun) {
      await profileRef.set(
        {
          usuario: alias,
          email,
          updatedAt: Timestamp.now(),
        },
        { merge: true },
      );
      await db.collection('aliases').doc(alias).set({
        uid: user.uid,
        email,
        alias,
        createdAt: Timestamp.now(),
      });
      if (currentAlias && currentAlias !== alias) {
        await db.collection('aliases').doc(currentAlias).delete();
      }
      migrated += 1;
    }
  }
  pageToken = page.pageToken;
} while (pageToken);

console.log(`\nMigrados: ${migrated} · Omitidos: ${skipped}${dryRun ? ' (dry run)' : ''}`);

function valueAfter(flag) {
  const index = args.indexOf(flag);
  if (index >= 0 && args[index + 1]) return args[index + 1];
  const inline = args.find((arg) => arg.startsWith(`${flag}=`));
  return inline ? inline.slice(flag.length + 1) : null;
}

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch (error) {
    fail(`No se pudo leer ${basename(path)}: ${error.message}`);
  }
}

function suggest(email) {
  const local = email.split('@')[0].toLowerCase();
  const clean = local
    .replace(/[^a-z0-9._-]/g, '')
    .replace(/^[._-]+|[._-]+$/g, '');
  return clean.length >= 3 ? clean : `totos${Date.now().toString().slice(-4)}`;
}

function normalize(value) {
  return String(value)
    .toLowerCase()
    .replace(/[\s._-]+/g, '')
    .replace(/4/g, 'a')
    .replace(/3/g, 'e')
    .replace(/1/g, 'i')
    .replace(/0/g, 'o')
    .replace(/5/g, 's')
    .replace(/7/g, 't');
}

function isReserved(alias) {
  const normalized = normalize(alias);
  return (
    reservedWords.has(normalized) ||
    ['admin', 'soporte', 'totos', 'staff'].some((prefix) =>
      normalized.startsWith(prefix),
    )
  );
}

async function uniqueAlias(base, uid) {
  let candidate = normalize(base).replace(/[^a-z0-9._-]/g, '');
  if (candidate.length < 3) candidate = `totos${Date.now().toString().slice(-4)}`;
  let suffix = 0;
  while (true) {
    const value = suffix === 0 ? candidate : `${candidate}${suffix}`;
    if (!isReserved(value)) {
      const ref = db.collection('aliases').doc(value);
      const snapshot = await ref.get();
      if (!snapshot.exists || snapshot.data()?.uid === uid) return value;
    }
    suffix += 1;
    if (suffix > 9999) return null;
  }
}

function fail(message) {
  console.error(`\n✖ ${message}\n`);
  process.exit(1);
}

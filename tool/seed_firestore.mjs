#!/usr/bin/env node
/**
 * Semilla idempotente de Firestore para TOTO'S Pizza (esquema en español).
 *
 * Lee `assets/data/*.json` (que NO se empaqueta en la app) y escribe:
 *
 *   productos/{id}        catálogo, precios en SOLES
 *   categorias/{id}       categorías ordenadas
 *   promociones/{id}      promociones (imagen propia o heredada del producto)
 *   sedes/{id}            solo las cuatro sedes del área de Huancayo
 *   configuracion/app     WhatsApp, teléfono, hero, pagos, reclamos, delivery
 *
 * Los importes se guardan en soles (`44`, `49.9`), no en céntimos.
 *
 * Requiere una clave de servicio del Admin SDK o el emulador de Firestore.
 * Volver a ejecutarlo deja los mismos documentos (no duplica nada).
 *
 * Uso:
 *   cd tool
 *   npm install
 *   node seed_firestore.mjs --credentials ../ruta/service-account.json
 *   node seed_firestore.mjs --dry-run
 *   node seed_firestore.mjs --prune-legacy   # borra el esquema anterior
 */
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { basename, dirname, extname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { cert, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..');
const DATA_DIR = join(ROOT, 'assets', 'data');
const PRODUCTS_DIR = join(ROOT, 'assets', 'images', 'products');

/** Sitios oficiales que sí se publican en la app. */
const BRANCH_IDS = ['huancayo', 'el-tambo', 'chilca', 'pio-pata'];

const BRANCH_META = {
  huancayo: { district: 'Huancayo', sortOrder: 1 },
  'el-tambo': { district: 'El Tambo', sortOrder: 2 },
  chilca: { district: 'Chilca', sortOrder: 3 },
  'pio-pata': { district: 'Pío Pata', sortOrder: 4 },
};

/** Placeholder de la beta: el negocio debe reemplazarlo antes de publicar. */
const WHATSAPP_PLACEHOLDER = '51900000000';
const PHONE_PLACEHOLDER = '51900000000';
const PHONE_DISPLAY_PLACEHOLDER = '900 000 000';

/** Carpeta pública del negocio en Google Drive («App_Imagenes»). */
const DEFAULT_DRIVE_FOLDER =
  'https://drive.google.com/drive/folders/1iXV2QjmlKV53xzJJ_9eXWfgEX31PM9p4';

/** Colecciones del esquema anterior, que deben migrarse. */
const LEGACY_COLLECTIONS = [
  'catalog',
  'categories',
  'branches',
  'promotions',
  'users',
  'orders',
  'claims',
  'settings',
];

// ── Argumentos ──────────────────────────────────────────────────────────────

function parseArgs(argv) {
  const args = {
    dryRun: false,
    prune: false,
    credentials: null,
    media: null,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--dry-run') args.dryRun = true;
    else if (arg === '--prune-legacy') args.prune = true;
    else if (arg === '--credentials') args.credentials = argv[++i];
    else if (arg.startsWith('--credentials=')) {
      args.credentials = arg.slice('--credentials='.length);
    } else if (arg === '--media') args.media = argv[++i];
    else if (arg.startsWith('--media=')) {
      args.media = arg.slice('--media='.length);
    } else if (arg === '--help' || arg === '-h') {
      printHelp();
      process.exit(0);
    } else {
      fail(`Argumento desconocido: ${arg}`);
    }
  }
  return args;
}

function printHelp() {
  console.log(`
Semilla de Firestore de TOTO'S Pizza (esquema en español, precios en soles)

Opciones:
  --credentials <ruta>   Clave de servicio del Admin SDK (JSON).
  --media <ruta>         Mapa de assets a IDs de Drive.
                         Por defecto: tool/drive_media.json si existe.
  --dry-run              Construye los documentos y los muestra sin escribir.
  --prune-legacy         Borra las colecciones del esquema anterior
                         (catalog, categories, branches, promotions,
                          users, orders, claims, settings).
  -h, --help             Esta ayuda.

Variables de entorno:
  GOOGLE_APPLICATION_CREDENTIALS  Clave de servicio si no usas --credentials.
  FIREBASE_PROJECT_ID             Proyecto destino (por defecto, el de la clave).
  FIRESTORE_EMULATOR_HOST         Usa el emulador local y omite credenciales.
  DRIVE_FOLDER_URL                Carpeta pública de Drive.
  DRIVE_MEDIA_FILE                Ruta del mapa de medios de Drive.
`);
}

function fail(message) {
  console.error(`\n✗ ${message}\n`);
  process.exit(1);
}

function log(message) {
  console.log(`· ${message}`);
}

// ── Carga de datos ──────────────────────────────────────────────────────────

function readJson(path, { required = true } = {}) {
  if (!existsSync(path)) {
    if (required) fail(`No se encontró el archivo requerido: ${path}`);
    return null;
  }
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch (error) {
    fail(`No se pudo leer ${basename(path)}: ${error.message}`);
  }
}

function assetIds(directory) {
  if (!existsSync(directory)) return new Set();
  return new Set(
    readdirSync(directory)
      .filter((file) => !file.startsWith('.'))
      .map((file) => basename(file, extname(file))),
  );
}

const localProductAssets = assetIds(PRODUCTS_DIR);

function loadMedia(args) {
  const candidate =
    args.media ?? process.env.DRIVE_MEDIA_FILE ?? join(HERE, 'drive_media.json');
  const path = isAbsolute(candidate) ? candidate : resolve(ROOT, candidate);
  const raw = readJson(path, { required: Boolean(args.media) });
  if (!raw) {
    log('Sin tool/drive_media.json: se usarán los assets locales de respaldo.');
    return {
      folderUrl:
        process.env.DRIVE_FOLDER_URL || DEFAULT_DRIVE_FOLDER,
      files: {},
    };
  }
  const files = raw.files ?? raw;
  return {
    folderUrl:
      raw.folderUrl ?? process.env.DRIVE_FOLDER_URL ?? DEFAULT_DRIVE_FOLDER,
    files: files && typeof files === 'object' ? files : {},
  };
}

// ── Medios ──────────────────────────────────────────────────────────────────

const DRIVE_PATH = /\/file\/d\/([a-zA-Z0-9_-]{10,})/;
const DRIVE_QUERY = /[?&]id=([a-zA-Z0-9_-]{10,})/;
const DRIVE_PLAIN = /^[a-zA-Z0-9_-]{20,}$/;

function driveIdFrom(value) {
  const text = String(value).trim();
  if (!text) return null;
  const path = text.match(DRIVE_PATH);
  if (path) return path[1];
  const query = text.match(DRIVE_QUERY);
  if (query) return query[1];
  if (DRIVE_PLAIN.test(text) && !text.includes('.')) return text;
  return null;
}

/** Convierte una clave del JSON en el `{url|driveId|assetName}` de MediaRef. */
function mediaFor(key, media, { assetFallback = key } = {}) {
  if (!key) return null;
  const value = media.files[key];
  if (typeof value === 'string' && value.trim()) {
    const driveId = driveIdFrom(value);
    if (driveId) return { driveId };
    if (/^https?:\/\//i.test(value.trim())) return { url: value.trim() };
    return { assetName: key };
  }
  if (typeof assetFallback === 'string') {
    if (assetFallback.startsWith('assets/')) return { assetName: assetFallback };
    if (localProductAssets.has(assetFallback)) {
      return { assetName: assetFallback };
    }
  }
  return null;
}

// ── Transformaciones ────────────────────────────────────────────────────────

function toInt(value, fallback = 0) {
  const number = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(number) ? Math.round(number) : fallback;
}

/** Normaliza un importe a soles con 2 decimales. */
function toSoles(value, fallback = 0) {
  const number = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.round(number * 100) / 100;
}

/** Convierte un ISO sin zona a hora de Lima (UTC-5). */
function toLimaDate(value) {
  if (!value) return null;
  const text = String(value).trim();
  if (!text) return null;
  const withZone = /(Z|[+-]\d{2}:?\d{2})$/i.test(text) ? text : `${text}-05:00`;
  const date = new Date(withZone);
  return Number.isNaN(date.getTime()) ? null : date;
}

function categoryDoc(category) {
  return {
    id: category.id,
    nombre: category.name,
    orden: toInt(category.order),
    activa: category.active !== false,
  };
}

function productDoc(product, media) {
  const imageKey = product.image ?? product.id;
  const gallery = [];
  for (const key of product.gallery ?? []) {
    if (!key || key === imageKey) continue;
    const mediaRef = mediaFor(key, media, { assetFallback: null });
    if (!mediaRef) continue;
    if (!gallery.some((item) => JSON.stringify(item) === JSON.stringify(mediaRef))) {
      gallery.push(mediaRef);
    }
  }

  const variants = (product.variants ?? []).map((variant) => {
    const doc = {
      etiqueta: variant.label ?? 'única',
      precio: toSoles(variant.priceSoles ?? variant.price),
    };
    if (variant.size) doc.tamano = variant.size;
    if (variant.slices != null) doc.rebanadas = toInt(variant.slices);
    return doc;
  });

  if (variants.length === 0) {
    fail(`El producto ${product.id} no tiene variantes con precio.`);
  }

  return {
    id: product.id,
    categoriaId: product.categoryId,
    nombre: product.name,
    descripcion: product.description ?? '',
    ...(product.summary ? { resumen: product.summary } : {}),
    imagen: mediaFor(imageKey, media),
    etiquetas: product.tags ?? [],
    disponible: product.available !== false,
    destacado: product.featured === true,
    ...(product.ingredients?.length ? { ingredientes: product.ingredients } : {}),
    ...(product.allergens?.length ? { alergenos: product.allergens } : {}),
    ...(product.calories != null ? { calorias: toInt(product.calories) } : {}),
    ...(product.portion ? { porcion: product.portion } : {}),
    ...(gallery.length ? { galeria: gallery } : {}),
    variantes: variants,
  };
}

function branchDoc(branch, defaults) {
  const meta = BRANCH_META[branch.id] ?? {};
  return {
    id: branch.id,
    nombre: branch.name,
    direccion: branch.address,
    distrito: meta.district ?? branch.district ?? '',
    provincia: 'Huancayo',
    ciudad: 'Huancayo',
    lat: Number(branch.lat),
    lng: Number(branch.lng),
    haceDelivery: branch.delivers !== false,
    costoDelivery: toSoles(defaults.deliveryFee),
    horario: {
      abre: branch.hours?.open ?? defaults.abre,
      cierra: branch.hours?.close ?? defaults.cierra,
      dias: branch.hours?.days ?? defaults.dias,
    },
    telefono: WHATSAPP_PLACEHOLDER,
    whatsapp: WHATSAPP_PLACEHOLDER,
    orden: meta.sortOrder ?? 1,
    activa: branch.active !== false,
    fechasCerradas: branch.closedDates ?? [],
  };
}

function promotionDoc(promotion, media, productImageByKey) {
  // Imagen propia si existe; si no, la del producto promocionado.
  const own = promotion.image
    ? mediaFor(promotion.image, media, { assetFallback: null })
    : null;
  const inherited = own ?? productImageByKey.get(promotion.productId) ?? null;

  const startsAt = toLimaDate(promotion.startsAt);
  const endsAt = toLimaDate(promotion.endsAt);
  const price =
    promotion.priceSoles != null
      ? toSoles(promotion.priceSoles)
      : promotion.price != null
        ? toSoles(promotion.price)
        : null;

  return {
    id: promotion.id,
    titulo: promotion.title,
    ...(promotion.subtitle ? { subtitulo: promotion.subtitle } : {}),
    productoId: promotion.productId,
    ...(promotion.variantLabel
      ? { etiquetaVariante: promotion.variantLabel }
      : {}),
    ...(promotion.discountPercent != null
      ? { descuentoPorcentaje: toInt(promotion.discountPercent) }
      : {}),
    ...(price != null ? { precio: price } : {}),
    ...(inherited ? { imagen: inherited } : {}),
    ...(startsAt ? { desde: Timestamp.fromDate(startsAt) } : {}),
    ...(endsAt ? { hasta: Timestamp.fromDate(endsAt) } : {}),
    banner: promotion.banner !== false,
    activa: promotion.active !== false,
  };
}

function settingsDoc({ delivery, payments, claims, media }) {
  const hero = mediaFor('hero-1', media, {
    assetFallback: 'assets/images/hero-1.webp',
  });
  return {
    whatsapp: WHATSAPP_PLACEHOLDER,
    telefono: PHONE_PLACEHOLDER,
    telefonoVisible: PHONE_DISPLAY_PLACEHOLDER,
    ...(media.folderUrl ? { carpetaDrive: media.folderUrl } : {}),
    ...(hero ? { imagenHero: hero } : {}),
    mediosPago: payments.map((method) => ({
      id: method.id,
      etiqueta: method.label,
      activo: method.active !== false,
    })),
    motivosReclamo: claims.map((reason) => ({
      id: reason.id,
      etiqueta: reason.label,
    })),
    delivery,
    updatedAt: Timestamp.now(),
  };
}

// ── Construcción del lote ───────────────────────────────────────────────────

function buildDocuments(media) {
  const menu = readJson(join(DATA_DIR, 'menu.json'));
  const branchSeed = readJson(join(DATA_DIR, 'branches.json'));
  const promotionSeed = readJson(join(DATA_DIR, 'promotions.json'));
  const deliverySeed = readJson(join(DATA_DIR, 'delivery.json'));
  const claimsSeed = readJson(join(DATA_DIR, 'claims.json'));
  const paymentsSeed = readJson(join(DATA_DIR, 'payment_methods.json'));

  // La categoría virtual «Las más pedidas» no es un grupo real de productos:
  // la app la antepone en la Carta y el documento heredado
  // `categorias/mas-pedidas` se ignora aunque siga en producción.
  const categories = (menu.categories ?? [])
    .filter((category) => category.id !== 'mas-pedidas')
    .map(categoryDoc);
  const products = (menu.products ?? []).map((product) =>
    productDoc(product, media),
  );
  if (categories.length === 0) fail('menu.json no tiene categorías.');
  if (products.length === 0) fail('menu.json no tiene productos.');

  // Imagen por producto, para heredarla en las promociones.
  const productImageByKey = new Map(
    products.map((product) => [product.id, product.imagen ?? null]),
  );

  const delivery = {
    base: toSoles(deliverySeed.base, 3),
    porKm: toSoles(deliverySeed.porKm, 1.5),
    gratisDesdeKm: Number(deliverySeed.gratisDesdeKm ?? 8),
    ...(deliverySeed.maxKm != null ? { maxKm: Number(deliverySeed.maxKm) } : {}),
  };

  const branchDefaults = {
    abre: branchSeed.defaultHours?.open ?? '12:45',
    cierra: branchSeed.defaultHours?.close ?? '21:30',
    dias: branchSeed.defaultHours?.days ?? [1, 2, 3, 4, 5, 6, 7],
    deliveryFee: delivery.base,
  };
  const branchSource = new Map(
    (branchSeed.branches ?? []).map((branch) => [branch.id, branch]),
  );
  const branches = BRANCH_IDS.map((id) =>
    branchDoc(
      { id, name: id, address: '', lat: 0, lng: 0, ...branchSource.get(id) },
      branchDefaults,
    ),
  );
  for (const branch of branches) {
    if (!branch.direccion) fail(`Falta la sede ${branch.id} en branches.json.`);
  }

  const promotions = (promotionSeed.promotions ?? []).map((promotion) =>
    promotionDoc(promotion, media, productImageByKey),
  );

  const settings = settingsDoc({
    delivery,
    payments: paymentsSeed.methods ?? [],
    claims: claimsSeed.reasons ?? [],
    media,
  });

  return { categories, products, branches, promotions, settings };
}

// ── Escritura ───────────────────────────────────────────────────────────────

function resolveCredentials(args) {
  const candidate =
    args.credentials ?? process.env.GOOGLE_APPLICATION_CREDENTIALS ?? null;
  if (!candidate) return null;
  const path = isAbsolute(candidate) ? candidate : resolve(ROOT, candidate);
  if (!existsSync(path)) {
    fail(
      `No se encontró la clave de servicio en ${path}. ` +
        'Descárgala desde Firebase Console o usa el emulador.',
    );
  }
  return { path, json: readJson(path) };
}

function documentEntries(documents) {
  return [
    ...documents.categories.map((doc) => [`categorias/${doc.id}`, doc]),
    ...documents.products.map((doc) => [`productos/${doc.id}`, doc]),
    ...documents.branches.map((doc) => [`sedes/${doc.id}`, doc]),
    ...documents.promotions.map((doc) => [`promociones/${doc.id}`, doc]),
    ['configuracion/app', documents.settings],
  ];
}

/** Detecta colecciones del esquema anterior en el proyecto destino. */
async function findLegacyCollections(db) {
  const found = [];
  for (const name of LEGACY_COLLECTIONS) {
    const snapshot = await db.collection(name).limit(1).get();
    if (!snapshot.empty) {
      const count = (await db.collection(name).count().get()).data().count;
      found.push({ name, count });
    }
  }
  return found;
}

async function pruneLegacyCollections(db, legacy) {
  for (const { name, count } of legacy) {
    const snapshot = await db.collection(name).get();
    const docs = snapshot.docs;
    for (let i = 0; i < docs.length; i += 400) {
      const batch = db.batch();
      for (const doc of docs.slice(i, i + 400)) batch.delete(doc.ref);
      await batch.commit();
    }
    log(`Borrada la colección legacy ${name} (${count} documentos).`);
  }
}

async function writeDocuments(db, documents, { dryRun, prune }) {
  const entries = documentEntries(documents);

  if (dryRun) {
    console.log('\n— Documentos que se escribirían (dry run) —');
    for (const [path, doc] of entries) {
      const text = JSON.stringify(doc);
      console.log(
        `  ${path}: ${text.slice(0, 220)}${text.length > 220 ? '…' : ''}`,
      );
    }
    console.log(`\nTotal: ${entries.length} documentos.`);
    return;
  }

  if (prune) {
    const legacy = await findLegacyCollections(db);
    if (legacy.length) {
      await pruneLegacyCollections(db, legacy);
    } else {
      log('No se encontraron colecciones legacy para borrar.');
    }
  }

  // Firestore limita los lotes a 500 operaciones.
  for (let i = 0; i < entries.length; i += 450) {
    const batch = db.batch();
    for (const [path, doc] of entries.slice(i, i + 450)) {
      batch.set(db.doc(path), doc);
    }
    await batch.commit();
  }

  console.log(`\n✓ ${entries.length} documentos escritos en Firestore.`);
}

// ── Arranque ────────────────────────────────────────────────────────────────

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const media = loadMedia(args);

  console.log("\nTOTO'S Pizza · semilla de Firestore (esquema en español)\n");
  const documents = buildDocuments(media);

  log(`Categorías: ${documents.categories.length}`);
  log(`Productos: ${documents.products.length}`);
  log(`Sedes publicadas: ${documents.branches.map((b) => b.id).join(', ')}`);
  log(`Promociones: ${documents.promotions.length}`);
  log('Configuración: configuracion/app');
  log(`Carpeta de Drive: ${documents.settings.carpetaDrive ?? '(sin definir)'}`);
  const sinImagen = documents.promotions.filter((p) => !p.imagen).length;
  if (sinImagen) {
    log(`Promociones sin imagen: ${sinImagen} (usarán el bloque de marca).`);
  }

  if (args.dryRun) {
    await writeDocuments(null, documents, args);
  } else {
    const emulator = process.env.FIRESTORE_EMULATOR_HOST;
    let appOptions;

    if (emulator) {
      log(`Emulador de Firestore: ${emulator}`);
      appOptions = {
        projectId: process.env.FIREBASE_PROJECT_ID || 'totospizza-3efbe',
      };
    } else {
      const credentials = resolveCredentials(args);
      if (!credentials) {
        fail(
          'Falta la clave de servicio. Usa --credentials <ruta>, define ' +
            'GOOGLE_APPLICATION_CREDENTIALS o inicia el emulador con ' +
            'FIRESTORE_EMULATOR_HOST.',
        );
      }
      appOptions = {
        credential: cert(credentials.json),
        projectId:
          process.env.FIREBASE_PROJECT_ID ||
          credentials.json.project_id ||
          'totospizza-3efbe',
      };
      log(`Clave de servicio: ${credentials.path}`);
    }

    const app = initializeApp(appOptions);
    const db = getFirestore(app);

    // Aborta si el proyecto sigue con el esquema anterior, salvo que se pida
    // migrarlo explícitamente con --prune-legacy.
    if (!args.prune) {
      const legacy = await findLegacyCollections(db);
      if (legacy.length) {
        await app.delete();
        fail(
          'El proyecto todavía tiene colecciones del esquema anterior: ' +
            legacy.map((l) => `${l.name} (${l.count})`).join(', ') +
            '.\n  Migra con --prune-legacy o bórralas antes de sembrar.',
        );
      }
    }

    await writeDocuments(db, documents, args);
    await app.delete();
  }

  log(
    `WhatsApp: ${WHATSAPP_PLACEHOLDER} (placeholder; reemplazar antes de publicar).`,
  );
  console.log(
    '\nLa app no lee estos JSON: Firestore es la única fuente en runtime.\n',
  );
}

main().catch((error) => {
  console.error('\n✗ La semilla falló:', error);
  process.exit(1);
});

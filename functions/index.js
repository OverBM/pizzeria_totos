import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

initializeApp();
const db = getFirestore();

const WINDOW_MS = 5 * 60 * 1000;
const MAX_ATTEMPTS = 10;

/**
 * Resuelve un alias a su correo.
 *
 * App Check se exige desde la configuración de la función. La respuesta es
 * homogénea: si el alias no existe devuelve `{ email: null }`, no un error
 * distinto que permita enumerar alias.
 */
export const resolveAlias = onCall(
  { enforceAppCheck: true, region: 'us-central1' },
  async (request) => {
    const alias = String(request.data?.alias ?? '').trim().toLowerCase();
    if (!alias) return { email: null };

    const ip = request.rawRequest.ip || 'unknown';
    await enforceRateLimit(`ip_${ip}`);
    await enforceRateLimit(`alias_${alias}`);

    const snapshot = await db.collection('aliases').doc(alias).get();
    if (!snapshot.exists) return { email: null };
    const email = snapshot.data()?.email;
    return { email: typeof email === 'string' ? email : null };
  },
);

async function enforceRateLimit(key) {
  const reference = db.collection('rateLimits').doc(key);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const now = Date.now();
    const data = snapshot.data() ?? {};
    const start = data.windowStart?.toMillis?.() ?? 0;
    const count = Number(data.count ?? 0);
    if (!start || now - start > WINDOW_MS) {
      transaction.set(reference, {
        windowStart: FieldValue.serverTimestamp(),
        count: 1,
      });
      return;
    }
    if (count >= MAX_ATTEMPTS) {
      throw new HttpsError(
        'resource-exhausted',
        'Demasiados intentos. Inténtalo más tarde.',
      );
    }
    transaction.update(reference, { count: count + 1 });
  });
}

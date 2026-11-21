// Shared helpers for the client-shape and gap test files. The older
// firestore.rules.test.js keeps its own copies on purpose: it predates this.
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');

const rules = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

let environment;

/// Call inside a `describe`: starts one environment for it and clears the
/// database before each test.
function useEnvironment() {
  before(async () => {
    environment = await initializeTestEnvironment({
      projectId: 'demo-veloce',
      firestore: { rules },
    });
    instances.clear();
  });
  beforeEach(async () => {
    instances.clear();
    await environment.clearFirestore();
  });
  after(() => environment.cleanup());
}

const OWNER = 'owner1';
const RENTER = 'renter4';
const OUTSIDER = 'renter5';

const instances = new Map();
const dbFor = (uid) => {
  if (!instances.has(uid)) {
    instances.set(uid, environment.authenticatedContext(uid).firestore());
  }
  return instances.get(uid);
};
const anon = () => environment.unauthenticatedContext().firestore();

async function seed(entries) {
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [p, data] of Object.entries(entries)) {
      await setDoc(doc(db, p), data);
    }
  });
}

async function admin(fn) {
  let result;
  await environment.withSecurityRulesDisabled(async (context) => {
    result = await fn(context.firestore());
  });
  return result;
}

const hours = (n) => new Date(Date.now() + n * 3600 * 1000);

/// The booking map as FirestoreRequestRepository writes it.
function bookingMap(overrides = {}) {
  return {
    reference: 'VLC-1234',
    vehicleId: 'car-1',
    renterId: RENTER,
    ownerId: OWNER,
    startDate: new Date('2026-12-20T09:00:00Z'),
    endDate: new Date('2026-12-22T09:00:00Z'),
    days: 2,
    dailyRateApplied: 45000,
    rentalFee: 90000,
    cautionFee: 100000,
    platformFee: 2000,
    totalPayable: 190000,
    status: 'pending',
    expiresAt: hours(24),
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

/// Ledger row as FirestoreLedgerWriter writes it (`at` is a server timestamp).
function ledgerMap(bookingId, type, from, to, amount, at, overrides = {}) {
  return {
    bookingId,
    vehicleId: 'car-1',
    ownerId: OWNER,
    renterId: RENTER,
    type,
    amount,
    fromParty: from,
    toParty: to,
    reference: 'REF',
    status: 'success',
    at,
    ...overrides,
  };
}

module.exports = {
  OWNER,
  RENTER,
  OUTSIDER,
  admin,
  anon,
  bookingMap,
  dbFor,
  hours,
  ledgerMap,
  seed,
  useEnvironment,
  get environment() {
    return environment;
  },
};

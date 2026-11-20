/* eslint-disable no-console */
// Run from this folder: npm test
// The Firebase CLI starts the local Firestore emulator and passes the rules
// from ../../firestore.rules. No production project or credentials are used.

const fs = require('fs');
const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} = require('firebase/firestore');

const PROJECT_ID = 'demo-veloce';
let environment;

const rules = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

function booking(renterId = 'renter4', overrides = {}) {
  return {
    reference: 'VLC-1234',
    vehicleId: 'car-1',
    renterId,
    ownerId: 'owner1',
    startDate: new Date('2026-11-20T09:00:00Z'),
    endDate: new Date('2026-11-22T09:00:00Z'),
    days: 2,
    dailyRateApplied: 45000,
    rentalFee: 90000,
    cautionFee: 100000,
    platformFee: 2000,
    totalPayable: 190000,
    status: 'pending',
    expiresAt: new Date('2026-11-21T09:00:00Z'),
    createdAt: new Date('2026-11-19T09:00:00Z'),
    updatedAt: new Date('2026-11-19T09:00:00Z'),
    ...overrides,
  };
}

function renterContact(bookingId = 'booking-1') {
  return {
    bookingId,
    phone: '0788100004',
    email: 'renter4@veloce.test',
    meetingPoint: null,
  };
}

async function seed() {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/owner1'), { role: 'owner' });
    await setDoc(doc(db, 'users/renter4'), { role: 'renter' });
    await setDoc(doc(db, 'users/renter5'), { role: 'renter' });
    await setDoc(doc(db, 'vehicles/car-1'), {
      ownerId: 'owner1',
      status: 'published',
    });
    await setDoc(doc(db, 'bookings/booking-1'), booking());
  });
}

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });
});

beforeEach(seed);

after(async () => {
  await environment.cleanup();
});

describe('favourites', () => {
  it('lets a renter write and read their own favourite', async () => {
    const db = environment.authenticatedContext('renter4').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users/renter4/favourites/car-1'), {
        userId: 'renter4',
        createdAt: new Date(),
      }),
    );
    await assertSucceeds(getDoc(doc(db, 'users/renter4/favourites/car-1')));
  });

  it('rejects writing another user\'s favourite', async () => {
    const db = environment.authenticatedContext('renter4').firestore();
    await assertFails(
      setDoc(doc(db, 'users/renter5/favourites/car-1'), {
        userId: 'renter5',
        createdAt: new Date(),
      }),
    );
  });

  it('rejects reading another user\'s favourite', async () => {
    await environment.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/renter5/favourites/car-1'), {
        userId: 'renter5',
        createdAt: new Date(),
      });
    });
    const db = environment.authenticatedContext('renter4').firestore();
    await assertFails(getDoc(doc(db, 'users/renter5/favourites/car-1')));
  });
});

describe('booking create', () => {
  it('allows a renter to create a pending booking and its contact in one batch', async () => {
    const db = environment.authenticatedContext('renter4').firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, 'bookings/booking-new'), booking('renter4'));
    batch.set(
      doc(db, 'bookings/booking-new/private/renter'),
      renterContact('booking-new'),
    );
    batch.set(doc(db, 'auditLogs/audit-new'), {
      actorId: 'renter4',
      entityType: 'booking',
      entityId: 'booking-new',
      oldState: null,
      newState: 'pending',
    });
    batch.set(doc(db, 'notifications/notification-new'), {
      userId: 'owner1',
      title: 'New booking request',
    });
    await assertSucceeds(batch.commit());
  });

  it('rejects a booking created for another renter', async () => {
    const db = environment.authenticatedContext('renter4').firestore();
    await assertFails(
      setDoc(doc(db, 'bookings/booking-new'), booking('renter5')),
    );
  });

  it('rejects a booking that does not start pending', async () => {
    const db = environment.authenticatedContext('renter4').firestore();
    await assertFails(
      setDoc(
        doc(db, 'bookings/booking-new'),
        booking('renter4', { status: 'approved' }),
      ),
    );
  });

  it('rejects the wrong platform fee or total', async () => {
    const db = environment.authenticatedContext('renter4').firestore();
    await assertFails(
      setDoc(
        doc(db, 'bookings/booking-new'),
        booking('renter4', { platformFee: 0 }),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, 'bookings/booking-new'),
        booking('renter4', { totalPayable: 1 }),
      ),
    );
  });

  it('rejects a booking whose owner does not match the vehicle', async () => {
    const db = environment.authenticatedContext('renter4').firestore();
    await assertFails(
      setDoc(
        doc(db, 'bookings/booking-new'),
        booking('renter4', { ownerId: 'owner2' }),
      ),
    );
  });
});

describe('booking contact', () => {
  it('lets only the renter write the renter contact document', async () => {
    const renter = environment.authenticatedContext('renter4').firestore();
    await assertSucceeds(
      setDoc(
        doc(renter, 'bookings/booking-1/private/renter'),
        renterContact(),
      ),
    );

    const owner = environment.authenticatedContext('owner1').firestore();
    await assertFails(
      setDoc(
        doc(owner, 'bookings/booking-1/private/renter'),
        renterContact(),
      ),
    );

    const otherRenter = environment.authenticatedContext('renter5').firestore();
    await assertFails(
      setDoc(
        doc(otherRenter, 'bookings/booking-1/private/renter'),
        renterContact(),
      ),
    );
  });
});

// ---------- Phase 5: handover, return, ledger, claims, repairs ----------

const OWNER = 'owner1';
const RENTER = 'renter4';
const OUTSIDER = 'renter5';

async function seedBooking(id, status, overrides = {}) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), `bookings/${id}`),
      booking(RENTER, { status, ...overrides }),
    );
  });
}

async function seedDoc(path, data) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

function dbFor(uid) {
  return environment.authenticatedContext(uid).firestore();
}

function ledgerRow(type, fromParty, toParty, amount, overrides = {}) {
  return {
    bookingId: 'booking-p5',
    ownerId: OWNER,
    renterId: RENTER,
    vehicleId: 'car-1',
    type,
    fromParty,
    toParty,
    amount,
    status: 'success',
    at: serverTimestamp(),
    ...overrides,
  };
}

const NOW = () => new Date();

describe('pickup (confirmed to active)', () => {
  const pickupBoth = () => ({
    status: 'active',
    ownerPickupConfirmedAt: NOW(),
    renterPickupConfirmedAt: NOW(),
    updatedAt: NOW(),
  });

  beforeEach(() => seedBooking('booking-p5', 'confirmed'));

  it('lets a party move to active with both pickup timestamps', async () => {
    await assertSucceeds(
      updateDoc(doc(dbFor(OWNER), 'bookings/booking-p5'), pickupBoth()),
    );
    await seedBooking('booking-p5b', 'confirmed');
    await assertSucceeds(
      updateDoc(doc(dbFor(RENTER), 'bookings/booking-p5b'), pickupBoth()),
    );
  });

  it('keeps the booking confirmed when only one side confirms', async () => {
    await assertSucceeds(
      updateDoc(doc(dbFor(OWNER), 'bookings/booking-p5'), {
        status: 'confirmed',
        ownerPickupConfirmedAt: NOW(),
        updatedAt: NOW(),
      }),
    );
  });

  it('rejects a non-party', async () => {
    await assertFails(
      updateDoc(doc(dbFor(OUTSIDER), 'bookings/booking-p5'), pickupBoth()),
    );
  });

  it('rejects touching other fields during pickup', async () => {
    await assertFails(
      updateDoc(doc(dbFor(OWNER), 'bookings/booking-p5'), {
        ...pickupBoth(),
        rentalFee: 1,
      }),
    );
  });

  it('rejects skipping straight from approved to active', async () => {
    await seedBooking('booking-p5c', 'approved');
    await assertFails(
      updateDoc(doc(dbFor(OWNER), 'bookings/booking-p5c'), pickupBoth()),
    );
  });
});

describe('return transitions', () => {
  it('lets a party start the return with returnedAt', async () => {
    await seedBooking('booking-p5', 'active');
    await assertSucceeds(
      updateDoc(doc(dbFor(RENTER), 'bookings/booking-p5'), {
        status: 'return',
        returnedAt: NOW(),
        updatedAt: NOW(),
      }),
    );
  });

  it('rejects starting the return without returnedAt', async () => {
    await seedBooking('booking-p5', 'active');
    await assertFails(
      updateDoc(doc(dbFor(RENTER), 'bookings/booking-p5'), {
        status: 'return',
        updatedAt: NOW(),
      }),
    );
  });

  it('rejects a non-party starting the return', async () => {
    await seedBooking('booking-p5', 'active');
    await assertFails(
      updateDoc(doc(dbFor(OUTSIDER), 'bookings/booking-p5'), {
        status: 'return',
        returnedAt: NOW(),
        updatedAt: NOW(),
      }),
    );
  });

  it('allows return to review with the return key set', async () => {
    await seedBooking('booking-p5', 'return', { returnedAt: NOW() });
    await assertSucceeds(
      updateDoc(doc(dbFor(OWNER), 'bookings/booking-p5'), {
        status: 'review',
        ownerReturnConfirmedAt: NOW(),
        renterReturnConfirmedAt: NOW(),
        cautionDecision: 'claim',
        lateDays: 0,
        lateFee: 0,
        lateFeeWaived: false,
        updatedAt: NOW(),
      }),
    );
  });

  it('rejects an extra key on return to review', async () => {
    await seedBooking('booking-p5', 'return', { returnedAt: NOW() });
    await assertFails(
      updateDoc(doc(dbFor(OWNER), 'bookings/booking-p5'), {
        status: 'review',
        cautionFee: 0,
        updatedAt: NOW(),
      }),
    );
  });

  it('allows return to completed with the settlement key set', async () => {
    await seedBooking('booking-p5', 'return', { returnedAt: NOW() });
    await assertSucceeds(
      updateDoc(doc(dbFor(RENTER), 'bookings/booking-p5'), {
        status: 'completed',
        cautionDecision: 'no_issue',
        renterOutcomeAckAt: NOW(),
        lateDays: 0,
        lateFee: 0,
        lateFeeWaived: false,
        completedAt: NOW(),
        updatedAt: NOW(),
      }),
    );
  });

  it('allows review to completed and rejects extra keys', async () => {
    await seedBooking('booking-p5', 'review');
    await assertFails(
      updateDoc(doc(dbFor(RENTER), 'bookings/booking-p5'), {
        status: 'completed',
        completedAt: NOW(),
        totalPayable: 0,
        updatedAt: NOW(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(dbFor(RENTER), 'bookings/booking-p5'), {
        status: 'completed',
        lateDays: 1,
        lateFee: 36000,
        completedAt: NOW(),
        updatedAt: NOW(),
      }),
    );
  });

  it('rejects completing from active', async () => {
    await seedBooking('booking-p5', 'active');
    await assertFails(
      updateDoc(doc(dbFor(RENTER), 'bookings/booking-p5'), {
        status: 'completed',
        completedAt: NOW(),
        updatedAt: NOW(),
      }),
    );
  });
});

describe('ledger entries at pickup (rentalFee 90000)', () => {
  beforeEach(() => seedBooking('booking-p5', 'active'));

  const add = (uid, row) =>
    setDoc(doc(dbFor(uid), 'transactions/tx-1'), row);

  it('allows release == rentalFee while the booking is active', async () => {
    await assertSucceeds(
      add(OWNER, ledgerRow('release', 'veloce', 'owner', 90000)),
    );
  });

  it('rejects a release that is not the rentalFee', async () => {
    await assertFails(
      add(OWNER, ledgerRow('release', 'veloce', 'owner', 89000)),
    );
  });

  it('allows platform_fee of exactly 2000', async () => {
    await assertSucceeds(
      add(OWNER, ledgerRow('platform_fee', 'owner', 'veloce', 2000)),
    );
    await assertFails(
      setDoc(
        doc(dbFor(OWNER), 'transactions/tx-2'),
        ledgerRow('platform_fee', 'owner', 'veloce', 1500),
      ),
    );
  });

  it('allows payout == rentalFee - 2000 only', async () => {
    await assertSucceeds(
      add(OWNER, ledgerRow('payout', 'veloce', 'owner', 88000)),
    );
    await assertFails(
      setDoc(
        doc(dbFor(OWNER), 'transactions/tx-2'),
        ledgerRow('payout', 'veloce', 'owner', 90000),
      ),
    );
  });

  it('rejects release, platform_fee and payout when not active', async () => {
    await seedBooking('booking-p5', 'confirmed');
    await assertFails(
      add(OWNER, ledgerRow('release', 'veloce', 'owner', 90000)),
    );
    await assertFails(
      setDoc(
        doc(dbFor(OWNER), 'transactions/tx-2'),
        ledgerRow('platform_fee', 'owner', 'veloce', 2000),
      ),
    );
    await assertFails(
      setDoc(
        doc(dbFor(OWNER), 'transactions/tx-3'),
        ledgerRow('payout', 'veloce', 'owner', 88000),
      ),
    );
  });

  it('rejects a non-party writing a ledger entry', async () => {
    await assertFails(
      add(OUTSIDER, ledgerRow('release', 'veloce', 'owner', 90000)),
    );
  });

  it('commits pickup and the three rows in one batch', async () => {
    await seedBooking('booking-p5', 'confirmed');
    const db = dbFor(OWNER);
    const batch = writeBatch(db);
    batch.update(doc(db, 'bookings/booking-p5'), {
      status: 'active',
      ownerPickupConfirmedAt: NOW(),
      renterPickupConfirmedAt: NOW(),
      updatedAt: NOW(),
    });
    batch.set(
      doc(db, 'transactions/tx-r'),
      ledgerRow('release', 'veloce', 'owner', 90000),
    );
    batch.set(
      doc(db, 'transactions/tx-f'),
      ledgerRow('platform_fee', 'owner', 'veloce', 2000),
    );
    batch.set(
      doc(db, 'transactions/tx-p'),
      ledgerRow('payout', 'veloce', 'owner', 88000),
    );
    await assertSucceeds(batch.commit());
  });
});

describe('ledger entries at settlement (cautionFee 100000)', () => {
  beforeEach(() => seedBooking('booking-p5', 'completed'));

  const add = (id, row) =>
    setDoc(doc(dbFor(OWNER), `transactions/${id}`), row);

  it('allows claim_deduction and late_fee up to the caution', async () => {
    await assertSucceeds(
      add('a', ledgerRow('claim_deduction', 'veloce', 'owner', 60000)),
    );
    await assertSucceeds(
      add('b', ledgerRow('late_fee', 'veloce', 'owner', 36000)),
    );
    await assertSucceeds(
      add('c', ledgerRow('claim_deduction', 'veloce', 'owner', 100000)),
    );
  });

  it('rejects claim_deduction and late_fee above the caution', async () => {
    await assertFails(
      add('a', ledgerRow('claim_deduction', 'veloce', 'owner', 100001)),
    );
    await assertFails(
      add('b', ledgerRow('late_fee', 'veloce', 'owner', 100001)),
    );
  });

  it('allows a caution refund up to the caution and rejects above', async () => {
    await assertSucceeds(
      add('a', ledgerRow('refund', 'veloce', 'renter', 100000)),
    );
    await assertFails(
      add('b', ledgerRow('refund', 'veloce', 'renter', 100001)),
    );
  });

  it('rejects zero or negative amounts', async () => {
    await assertFails(
      add('a', ledgerRow('refund', 'veloce', 'renter', 0)),
    );
  });

  it('rejects settlement rows while the booking is not completed', async () => {
    await seedBooking('booking-p5', 'review');
    await assertFails(
      add('a', ledgerRow('claim_deduction', 'veloce', 'owner', 1000)),
    );
    await assertFails(
      add('b', ledgerRow('late_fee', 'veloce', 'owner', 1000)),
    );
    await assertFails(
      add('c', ledgerRow('refund', 'veloce', 'renter', 1000)),
    );
  });

  it('rejects a claim_deduction paid to the renter', async () => {
    await assertFails(
      add('a', ledgerRow('claim_deduction', 'veloce', 'renter', 1000)),
    );
  });

  it('commits completion, deduction, late fee and refund in one batch', async () => {
    await seedBooking('booking-p5', 'review');
    const db = dbFor(RENTER);
    const batch = writeBatch(db);
    batch.update(doc(db, 'bookings/booking-p5'), {
      status: 'completed',
      lateDays: 1,
      lateFee: 36000,
      completedAt: NOW(),
      updatedAt: NOW(),
    });
    batch.set(
      doc(db, 'transactions/tx-d'),
      ledgerRow('claim_deduction', 'veloce', 'owner', 40000),
    );
    batch.set(
      doc(db, 'transactions/tx-l'),
      ledgerRow('late_fee', 'veloce', 'owner', 36000),
    );
    batch.set(
      doc(db, 'transactions/tx-f'),
      ledgerRow('refund', 'veloce', 'renter', 24000),
    );
    await assertSucceeds(batch.commit());
  });
});

describe('ledger is append-only', () => {
  beforeEach(async () => {
    await seedBooking('booking-p5', 'active');
    await seedDoc('transactions/tx-1', {
      ...ledgerRow('release', 'veloce', 'owner', 90000),
      at: NOW(),
    });
  });

  it('rejects updating a transaction as either party', async () => {
    await assertFails(
      updateDoc(doc(dbFor(OWNER), 'transactions/tx-1'), { amount: 1 }),
    );
    await assertFails(
      updateDoc(doc(dbFor(RENTER), 'transactions/tx-1'), { amount: 1 }),
    );
  });

  it('lets only the parties read the row', async () => {
    await assertSucceeds(getDoc(doc(dbFor(OWNER), 'transactions/tx-1')));
    await assertFails(getDoc(doc(dbFor(OUTSIDER), 'transactions/tx-1')));
  });
});

describe('cautionClaims', () => {
  const claim = (amount, overrides = {}) => ({
    bookingId: 'booking-p5',
    amount,
    originalAmount: amount,
    reason: 'Scratched bumper',
    ...overrides,
  });

  beforeEach(() => seedBooking('booking-p5', 'review'));

  it('lets the owner create a claim of 0 < amount <= cautionFee', async () => {
    await assertSucceeds(
      setDoc(doc(dbFor(OWNER), 'cautionClaims/booking-p5'), claim(100000)),
    );
  });

  it('rejects zero, negative or above-caution amounts', async () => {
    await assertFails(
      setDoc(doc(dbFor(OWNER), 'cautionClaims/booking-p5'), claim(0)),
    );
    await assertFails(
      setDoc(doc(dbFor(OWNER), 'cautionClaims/booking-p5'), claim(-5)),
    );
    await assertFails(
      setDoc(doc(dbFor(OWNER), 'cautionClaims/booking-p5'), claim(100001)),
    );
  });

  it('rejects creation by the renter or an outsider', async () => {
    await assertFails(
      setDoc(doc(dbFor(RENTER), 'cautionClaims/booking-p5'), claim(1000)),
    );
    await assertFails(
      setDoc(doc(dbFor(OUTSIDER), 'cautionClaims/booking-p5'), claim(1000)),
    );
  });

  it('rejects a claim whose bookingId differs from its path', async () => {
    await assertFails(
      setDoc(
        doc(dbFor(OWNER), 'cautionClaims/booking-p5'),
        claim(1000, { bookingId: 'other' }),
      ),
    );
  });

  describe('existing claim', () => {
    beforeEach(() => seedDoc('cautionClaims/booking-p5', claim(50000)));

    it('lets either party update within the caution', async () => {
      await assertSucceeds(
        updateDoc(doc(dbFor(RENTER), 'cautionClaims/booking-p5'), {
          renterResponse: 'disputed',
        }),
      );
      await assertSucceeds(
        updateDoc(doc(dbFor(OWNER), 'cautionClaims/booking-p5'), {
          amount: 30000,
        }),
      );
    });

    it('rejects an update above the caution or by an outsider', async () => {
      await assertFails(
        updateDoc(doc(dbFor(OWNER), 'cautionClaims/booking-p5'), {
          amount: 100001,
        }),
      );
      await assertFails(
        updateDoc(doc(dbFor(OUTSIDER), 'cautionClaims/booking-p5'), {
          renterResponse: 'agreed',
        }),
      );
    });

    it('lets parties read but not an outsider', async () => {
      await assertSucceeds(getDoc(doc(dbFor(OWNER), 'cautionClaims/booking-p5')));
      await assertSucceeds(getDoc(doc(dbFor(RENTER), 'cautionClaims/booking-p5')));
      await assertFails(getDoc(doc(dbFor(OUTSIDER), 'cautionClaims/booking-p5')));
    });

    it('rejects deleting a claim', async () => {
      await assertFails(
        require('firebase/firestore').deleteDoc(
          doc(dbFor(OWNER), 'cautionClaims/booking-p5'),
        ),
      );
    });
  });
});

describe('repairExpenses', () => {
  const expense = (overrides = {}) => ({
    ownerId: OWNER,
    bookingId: 'booking-p5',
    amount: 120000,
    description: 'Bumper repair',
    receiptUrl: 'https://example.test/receipt.jpg',
    ...overrides,
  });

  beforeEach(() => seedBooking('booking-p5', 'review'));

  it('lets only the booking owner create an expense', async () => {
    await assertSucceeds(
      setDoc(doc(dbFor(OWNER), 'repairExpenses/exp-1'), expense()),
    );
    await assertFails(
      setDoc(
        doc(dbFor(RENTER), 'repairExpenses/exp-2'),
        expense({ ownerId: RENTER }),
      ),
    );
    await assertFails(
      setDoc(
        doc(dbFor(OUTSIDER), 'repairExpenses/exp-3'),
        expense({ ownerId: OUTSIDER }),
      ),
    );
  });

  it('rejects zero amount or empty description', async () => {
    await assertFails(
      setDoc(doc(dbFor(OWNER), 'repairExpenses/exp-1'), expense({ amount: 0 })),
    );
    await assertFails(
      setDoc(
        doc(dbFor(OWNER), 'repairExpenses/exp-1'),
        expense({ description: '' }),
      ),
    );
  });

  it('lets only the owner read and update an expense', async () => {
    await seedDoc('repairExpenses/exp-1', expense());
    await assertSucceeds(getDoc(doc(dbFor(OWNER), 'repairExpenses/exp-1')));
    await assertFails(getDoc(doc(dbFor(RENTER), 'repairExpenses/exp-1')));
    await assertSucceeds(
      updateDoc(doc(dbFor(OWNER), 'repairExpenses/exp-1'), { amount: 130000 }),
    );
    await assertFails(
      updateDoc(doc(dbFor(RENTER), 'repairExpenses/exp-1'), { amount: 1 }),
    );
  });
});

// These encode what the Phase 5 repository and task expect. They failed
// against the first merged firestore.rules and pass since the rules were fixed.
describe('pickup needs both timestamps, dispute and re-claim stay in review', () => {
  it('rejects confirmed to active when a pickup timestamp is missing', async () => {
    await seedBooking('booking-p5', 'confirmed');
    await assertFails(
      updateDoc(doc(dbFor(OWNER), 'bookings/booking-p5'), {
        status: 'active',
        ownerPickupConfirmedAt: NOW(),
        updatedAt: NOW(),
      }),
    );
  });

  it('allows a dispute write that keeps the booking in review', async () => {
    await seedBooking('booking-p5', 'review');
    await assertSucceeds(
      updateDoc(doc(dbFor(RENTER), 'bookings/booking-p5'), {
        updatedAt: NOW(),
      }),
    );
  });
});

// ---------- Phase 6: reviews, rating aggregates, notifications ----------

const REVIEW_USER = 'booking-p6_renter4_user';
const REVIEW_CAR = 'booking-p6_renter4_vehicle';

function review(overrides = {}) {
  return {
    bookingId: 'booking-p6',
    authorId: RENTER,
    subjectType: 'user',
    subjectId: OWNER,
    stars: 4,
    comment: 'Smooth handover',
    createdAt: new Date(),
    editedAt: null,
    ...overrides,
  };
}

function appNotification(overrides = {}) {
  return {
    userId: OWNER,
    type: 'request_received',
    bookingId: 'booking-p6',
    read: false,
    createdAt: new Date(),
    ...overrides,
  };
}

// Reviewed users and cars start with an aggregate, like the seed does.
async function seedRated() {
  await seedBooking('booking-p6', 'completed');
  await seedDoc('users/owner1', {
    role: 'owner',
    ratingAvg: 4,
    ratingCount: 2,
  });
  await seedDoc('users/renter4', {
    role: 'renter',
    ratingAvg: 5,
    ratingCount: 1,
  });
  await seedDoc('vehicles/car-1', {
    ownerId: OWNER,
    status: 'published',
    ratingAvg: 4,
    ratingCount: 2,
  });
}

describe('reviews', () => {
  beforeEach(seedRated);

  it('lets an author create their own review', async () => {
    await assertSucceeds(
      setDoc(doc(dbFor(RENTER), `reviews/${REVIEW_USER}`), review()),
    );
  });

  it('rejects creating a review as someone else', async () => {
    await assertFails(
      setDoc(
        doc(dbFor(OUTSIDER), `reviews/${REVIEW_USER}`),
        review({ authorId: RENTER }),
      ),
    );
  });

  it('lets any signed-in user read a review', async () => {
    await seedDoc(`reviews/${REVIEW_USER}`, review());
    await assertSucceeds(getDoc(doc(dbFor(OUTSIDER), `reviews/${REVIEW_USER}`)));
    await assertSucceeds(getDoc(doc(dbFor(OWNER), `reviews/${REVIEW_USER}`)));
  });

  describe('existing review', () => {
    beforeEach(() => seedDoc(`reviews/${REVIEW_USER}`, review()));

    it('lets the author edit stars and comment', async () => {
      await assertSucceeds(
        updateDoc(doc(dbFor(RENTER), `reviews/${REVIEW_USER}`), {
          stars: 5,
          comment: 'Even better on reflection',
          editedAt: new Date(),
        }),
      );
    });

    it('rejects an edit by anyone else, including the subject', async () => {
      await assertFails(
        updateDoc(doc(dbFor(OWNER), `reviews/${REVIEW_USER}`), { stars: 1 }),
      );
      await assertFails(
        updateDoc(doc(dbFor(OUTSIDER), `reviews/${REVIEW_USER}`), { stars: 1 }),
      );
    });

    it('rejects changing authorId, bookingId, subjectId or subjectType', async () => {
      const ref = doc(dbFor(RENTER), `reviews/${REVIEW_USER}`);
      await assertFails(updateDoc(ref, { authorId: OUTSIDER }));
      await assertFails(updateDoc(ref, { bookingId: 'booking-other' }));
      await assertFails(updateDoc(ref, { subjectId: OUTSIDER }));
      await assertFails(updateDoc(ref, { subjectType: 'vehicle' }));
    });

    it('lets the author, the subject and a booking party delete', async () => {
      // Author.
      await assertSucceeds(
        deleteDoc(doc(dbFor(RENTER), `reviews/${REVIEW_USER}`)),
      );
      // Subject (owner1 is also a party, so check a car review separately).
      await seedDoc(`reviews/${REVIEW_USER}`, review());
      await assertSucceeds(
        deleteDoc(doc(dbFor(OWNER), `reviews/${REVIEW_USER}`)),
      );
      // Booking party for a car review: subjectId is the car, not the user.
      await seedDoc(
        `reviews/${REVIEW_CAR}`,
        review({ subjectType: 'vehicle', subjectId: 'car-1' }),
      );
      await assertSucceeds(
        deleteDoc(doc(dbFor(OWNER), `reviews/${REVIEW_CAR}`)),
      );
    });

    it('rejects delete by someone unrelated to the review', async () => {
      await assertFails(
        deleteDoc(doc(dbFor(OUTSIDER), `reviews/${REVIEW_USER}`)),
      );
    });
  });
});

describe('rating aggregate (users)', () => {
  beforeEach(seedRated);

  const rate = (uid, target, data) =>
    updateDoc(doc(dbFor(uid), `users/${target}`), data);

  it('lets a non-owner add one rating', async () => {
    await assertSucceeds(
      rate(RENTER, 'owner1', { ratingAvg: 4.3, ratingCount: 3 }),
    );
  });

  it('lets a non-owner change the average with the count unchanged (edit)', async () => {
    await assertSucceeds(
      rate(RENTER, 'owner1', { ratingAvg: 3.5, ratingCount: 2 }),
    );
  });

  it('accepts the bounds 1 and 5', async () => {
    await assertSucceeds(
      rate(RENTER, 'owner1', { ratingAvg: 1, ratingCount: 3 }),
    );
    await assertSucceeds(
      rate(RENTER, 'owner1', { ratingAvg: 5, ratingCount: 3 }),
    );
  });

  it('rejects changing another field in the same write', async () => {
    await assertFails(
      rate(RENTER, 'owner1', {
        ratingAvg: 4.3,
        ratingCount: 3,
        role: 'renter',
      }),
    );
    await assertFails(rate(RENTER, 'owner1', { completedCount: 10 }));
    await assertFails(rate(RENTER, 'owner1', { verified: true }));
  });

  it('rejects a count that jumps by 2 or goes down', async () => {
    await assertFails(
      rate(RENTER, 'owner1', { ratingAvg: 4.3, ratingCount: 4 }),
    );
    await assertFails(
      rate(RENTER, 'owner1', { ratingAvg: 4.3, ratingCount: 1 }),
    );
    await assertFails(
      rate(RENTER, 'owner1', { ratingAvg: 4.3, ratingCount: 0 }),
    );
  });

  it('rejects an average of 0 or above 5', async () => {
    await assertFails(
      rate(RENTER, 'owner1', { ratingAvg: 0, ratingCount: 3 }),
    );
    await assertFails(
      rate(RENTER, 'owner1', { ratingAvg: 0.9, ratingCount: 3 }),
    );
    await assertFails(
      rate(RENTER, 'owner1', { ratingAvg: 5.1, ratingCount: 3 }),
    );
    await assertFails(
      rate(RENTER, 'owner1', { ratingAvg: 6, ratingCount: 3 }),
    );
  });

  it('rejects an owner changing their own rating', async () => {
    await assertFails(
      rate(OWNER, 'owner1', { ratingAvg: 5, ratingCount: 3 }),
    );
    await assertFails(rate(OWNER, 'owner1', { ratingAvg: 5 }));
  });

  it('still lets an owner edit their own profile fields', async () => {
    await assertSucceeds(rate(OWNER, 'owner1', { displayName: 'Owner One' }));
  });
});

describe('rating aggregate (vehicles)', () => {
  beforeEach(seedRated);

  const rate = (uid, data) =>
    updateDoc(doc(dbFor(uid), 'vehicles/car-1'), data);

  it('rejects the owner changing their own car rating', async () => {
    await assertFails(rate(OWNER, { ratingAvg: 5, ratingCount: 3 }));
    await assertFails(rate(OWNER, { ratingAvg: 5 }));
    await assertFails(rate(OWNER, { ratingCount: 50 }));
  });

  it('still lets the owner edit the listing fields', async () => {
    await assertSucceeds(rate(OWNER, { dailyPrice: 60000 }));
  });

  it('lets a non-owner add one rating or edit the average', async () => {
    await assertSucceeds(rate(RENTER, { ratingAvg: 4.3, ratingCount: 3 }));
    await assertSucceeds(rate(RENTER, { ratingAvg: 3.5, ratingCount: 3 }));
  });

  it('rejects changing another field', async () => {
    await assertFails(
      rate(RENTER, { ratingAvg: 4.3, ratingCount: 3, dailyRate: 1000 }),
    );
    await assertFails(rate(RENTER, { status: 'hidden' }));
    await assertFails(rate(RENTER, { ownerId: RENTER }));
  });

  it('rejects a count that jumps by 2 or goes down', async () => {
    await assertFails(rate(RENTER, { ratingAvg: 4.3, ratingCount: 4 }));
    await assertFails(rate(RENTER, { ratingAvg: 4.3, ratingCount: 1 }));
  });

  it('rejects an average of 0 or above 5', async () => {
    await assertFails(rate(RENTER, { ratingAvg: 0, ratingCount: 3 }));
    await assertFails(rate(RENTER, { ratingAvg: 5.5, ratingCount: 3 }));
  });
});

// Mirrors FirestoreReviewRepository.submitReview: one batch with the review
// and the subject's new aggregate.
describe('review batch (review + aggregate)', () => {
  beforeEach(seedRated);

  it('writes a user review and the aggregate together', async () => {
    const db = dbFor(RENTER);
    const batch = writeBatch(db);
    batch.set(doc(db, `reviews/${REVIEW_USER}`), review());
    batch.update(doc(db, 'users/owner1'), { ratingAvg: 4, ratingCount: 3 });
    await assertSucceeds(batch.commit());
  });

  it('writes a car review and the aggregate together', async () => {
    const db = dbFor(RENTER);
    const batch = writeBatch(db);
    batch.set(
      doc(db, `reviews/${REVIEW_CAR}`),
      review({ subjectType: 'vehicle', subjectId: 'car-1' }),
    );
    batch.update(doc(db, 'vehicles/car-1'), { ratingAvg: 4, ratingCount: 3 });
    await assertSucceeds(batch.commit());
  });

  it('writes an owner-to-renter review and the aggregate together', async () => {
    const db = dbFor(OWNER);
    const batch = writeBatch(db);
    batch.set(
      doc(db, 'reviews/booking-p6_owner1_user'),
      review({ authorId: OWNER, subjectId: RENTER }),
    );
    batch.update(doc(db, 'users/renter4'), { ratingAvg: 4.5, ratingCount: 2 });
    await assertSucceeds(batch.commit());
  });

  it('writes an edit and the recomputed average (count unchanged)', async () => {
    await seedDoc(`reviews/${REVIEW_USER}`, review());
    const db = dbFor(RENTER);
    const batch = writeBatch(db);
    batch.update(doc(db, `reviews/${REVIEW_USER}`), {
      stars: 5,
      comment: 'Updated',
      editedAt: new Date(),
    });
    batch.update(doc(db, 'users/owner1'), { ratingAvg: 4.5, ratingCount: 2 });
    await assertSucceeds(batch.commit());
  });

  it('fails the whole batch when the aggregate is out of bounds', async () => {
    const db = dbFor(RENTER);
    const batch = writeBatch(db);
    batch.set(doc(db, `reviews/${REVIEW_USER}`), review());
    batch.update(doc(db, 'users/owner1'), { ratingAvg: 4, ratingCount: 5 });
    await assertFails(batch.commit());
    await environment.withSecurityRulesDisabled(async (context) => {
      const snap = await getDoc(doc(context.firestore(), `reviews/${REVIEW_USER}`));
      if (snap.exists()) throw new Error('review must not be written');
    });
  });

  it('fails the batch when the review is written for another author', async () => {
    const db = dbFor(OUTSIDER);
    const batch = writeBatch(db);
    batch.set(doc(db, `reviews/${REVIEW_USER}`), review());
    batch.update(doc(db, 'users/owner1'), { ratingAvg: 4, ratingCount: 3 });
    await assertFails(batch.commit());
  });
});

describe('notifications', () => {
  it('lets any signed-in user create a notification for someone else', async () => {
    await assertSucceeds(
      setDoc(doc(dbFor(RENTER), 'notifications/n-1'), appNotification()),
    );
  });

  describe('existing notification', () => {
    beforeEach(() => seedDoc('notifications/n-1', appNotification()));

    it('lets only the owner read it', async () => {
      await assertSucceeds(getDoc(doc(dbFor(OWNER), 'notifications/n-1')));
      await assertFails(getDoc(doc(dbFor(RENTER), 'notifications/n-1')));
    });

    it('lets only the owner mark it read', async () => {
      await assertSucceeds(
        updateDoc(doc(dbFor(OWNER), 'notifications/n-1'), { read: true }),
      );
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'notifications/n-1'), { read: true }),
      );
    });

    it('lets only the owner delete it', async () => {
      await assertFails(deleteDoc(doc(dbFor(RENTER), 'notifications/n-1')));
      await assertSucceeds(deleteDoc(doc(dbFor(OWNER), 'notifications/n-1')));
    });
  });
});

describe('unauthenticated access (phase 6 collections)', () => {
  const anon = () => environment.unauthenticatedContext().firestore();

  beforeEach(async () => {
    await seedRated();
    await seedDoc(`reviews/${REVIEW_USER}`, review());
    await seedDoc('notifications/n-1', appNotification());
  });

  it('denies reviews', async () => {
    await assertFails(getDoc(doc(anon(), `reviews/${REVIEW_USER}`)));
    await assertFails(setDoc(doc(anon(), 'reviews/new'), review()));
    await assertFails(
      updateDoc(doc(anon(), `reviews/${REVIEW_USER}`), { stars: 1 }),
    );
    await assertFails(deleteDoc(doc(anon(), `reviews/${REVIEW_USER}`)));
  });

  it('denies rating aggregates on users and vehicles', async () => {
    await assertFails(
      updateDoc(doc(anon(), 'users/owner1'), { ratingAvg: 4, ratingCount: 3 }),
    );
    await assertFails(
      updateDoc(doc(anon(), 'vehicles/car-1'), {
        ratingAvg: 4,
        ratingCount: 3,
      }),
    );
  });

  it('denies notifications', async () => {
    await assertFails(getDoc(doc(anon(), 'notifications/n-1')));
    await assertFails(setDoc(doc(anon(), 'notifications/n-2'), appNotification()));
    await assertFails(
      updateDoc(doc(anon(), 'notifications/n-1'), { read: true }),
    );
    await assertFails(deleteDoc(doc(anon(), 'notifications/n-1')));
  });
});

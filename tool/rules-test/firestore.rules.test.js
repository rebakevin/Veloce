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

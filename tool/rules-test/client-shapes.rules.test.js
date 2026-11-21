/* eslint-disable no-console */
// The real client write and query shapes, taken from lib/ (see each block):
// booking batches (firestore_booking_repository.dart), claim writes
// (CautionClaimModel.toMap, firestore_handover_repository.dart), the list
// queries each repository issues, and the account eraser.
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} = require('firebase/firestore');
const s = require('./support');
const { OWNER, RENTER, OUTSIDER, bookingMap, dbFor, ledgerMap } = s;

const ts = (d = new Date()) => Timestamp.fromDate(d);

const userDoc = (role) => ({
  role,
  ratingAvg: 0,
  ratingCount: 0,
  completedCount: 0,
});

const audit = (db, batch, actor, id, from, to) =>
  batch.set(doc(collection(db, 'auditLogs')), {
    actorId: actor,
    entityType: 'booking',
    entityId: id,
    oldState: from,
    newState: to,
    createdAt: serverTimestamp(),
  });

const note = (db, batch, userId, bookingId) =>
  batch.set(doc(collection(db, 'notifications')), {
    userId,
    type: 'requestApproved',
    title: 'T',
    text: 'x',
    bookingId,
    read: false,
    createdAt: serverTimestamp(),
  });

// The wire map of CautionClaimModel.toMap.
const claimMap = (overrides = {}) => ({
  bookingId: 'b-ret',
  originalAmount: 50000,
  currentAmount: 50000,
  reason: 'Scratched bumper',
  evidenceUrls: ['https://x.test/storage/v1/object/public/e/1.jpg'],
  renterResponse: 'none',
  history: [
    { amount: 50000, reason: 'Scratched bumper', at: ts(), response: 'none' },
  ],
  status: 'open',
  updatedAt: ts(),
  ...overrides,
});

const seedBase = () =>
  s.seed({
    'users/owner1': userDoc('owner'),
    'users/renter4': userDoc('renter'),
    'users/renter5': userDoc('renter'),
    'vehicles/car-1': {
      ownerId: OWNER,
      status: 'published',
      neighbourhood: 'Kacyiru',
      docsValidUntil: new Date('2030-01-01T00:00:00Z'),
      createdAt: new Date(),
    },
  });

describe('client shapes: bookings (phase 4)', () => {
  s.useEnvironment();
  beforeEach(seedBase);

  describe('approve batch', () => {
    beforeEach(() =>
      s.seed({
        'bookings/b-1': bookingMap(),
        'bookings/b-2': bookingMap({ renterId: OUTSIDER }), // overlaps b-1
      }),
    );

    const approve = (uid = OWNER, { lockFor = RENTER, date = false } = {}) => {
      const db = dbFor(uid);
      const batch = writeBatch(db);
      batch.update(doc(db, 'bookings/b-1'), {
        status: 'approved',
        payDeadline: ts(new Date(Date.now() + 86400000)),
        updatedAt: date ? new Date() : serverTimestamp(),
      });
      batch.set(doc(db, 'bookings/b-1/private/owner'), {
        bookingId: 'b-1',
        phone: '0788',
        email: 'o@v.test',
        meetingPoint: 'Kacyiru roundabout',
      });
      batch.set(doc(db, `renterLocks/${lockFor}`), {
        bookingId: 'b-1',
        createdAt: serverTimestamp(),
      });
      batch.set(doc(db, 'calendarBlocks/b-1'), {
        bookingId: 'b-1',
        vehicleId: 'car-1',
        startDate: ts(new Date('2026-12-20T09:00:00Z')),
        endDate: ts(new Date('2026-12-22T09:00:00Z')),
      });
      // _declineOverlap
      batch.update(doc(db, 'bookings/b-2'), {
        status: 'declined',
        reason: 'The car has been booked for these dates.',
        updatedAt: serverTimestamp(),
      });
      audit(db, batch, uid, 'b-1', 'pending', 'approved');
      note(db, batch, RENTER, 'b-1');
      return batch.commit();
    };

    it('commits with calendar block, lock, owner contact and overlap decline', async () => {
      await assertSucceeds(approve());
    });

    it('rejects approval by the renter, an outsider or with a client date', async () => {
      await assertFails(approve(RENTER));
      await assertFails(approve(OUTSIDER));
      await assertFails(approve(OWNER, { date: true }));
    });

    it('rejects a lock for a renter who is not on the booking', async () => {
      await assertFails(approve(OWNER, { lockFor: OUTSIDER }));
    });

    it('rejects approval while a live booking holds the renter lock', async () => {
      await s.seed({
        'bookings/b-live': bookingMap({ status: 'approved' }),
        'renterLocks/renter4': { bookingId: 'b-live', createdAt: new Date() },
      });
      await assertFails(approve());
    });

    it('replaces a lock held by a dead booking', async () => {
      for (const dead of ['expired', 'cancelled', 'declined']) {
        await s.environment.clearFirestore();
        await seedBase();
        await s.seed({
          'bookings/b-1': bookingMap(),
          'bookings/b-2': bookingMap({ renterId: OUTSIDER }),
          'bookings/b-dead': bookingMap({ status: dead }),
          'renterLocks/renter4': { bookingId: 'b-dead', createdAt: new Date() },
        });
        await assertSucceeds(approve());
      }
    });

    it('cannot create an approval calendar block for a pending booking', async () => {
      await assertFails(
        setDoc(doc(dbFor(OWNER), 'calendarBlocks/b-1'), {
          bookingId: 'b-1',
          vehicleId: 'car-1',
          startDate: ts(),
          endDate: ts(),
        }),
      );
    });
  });

  describe('decline', () => {
    beforeEach(() => s.seed({ 'bookings/b-1': bookingMap() }));
    const decline = (uid, reason) => {
      const db = dbFor(uid);
      const batch = writeBatch(db);
      batch.update(doc(db, 'bookings/b-1'), {
        status: 'declined',
        reason,
        updatedAt: serverTimestamp(),
      });
      audit(db, batch, uid, 'b-1', 'pending', 'declined');
      note(db, batch, RENTER, 'b-1');
      return batch.commit();
    };

    it('lets the owner decline with a reason', async () => {
      await assertSucceeds(decline(OWNER, 'Not available'));
    });
    it('rejects an empty reason, the renter and an outsider', async () => {
      await assertFails(decline(OWNER, ''));
      await assertFails(decline(RENTER, 'x'));
      await assertFails(decline(OUTSIDER, 'x'));
    });
  });

  describe('cancel', () => {
    const cancel = (uid, id, { refund = 0, block = true, lock = true } = {}) => {
      const db = dbFor(uid);
      const batch = writeBatch(db);
      batch.update(doc(db, `bookings/${id}`), {
        status: 'cancelled',
        reason: 'Cancelled before pickup was confirmed.',
        updatedAt: serverTimestamp(),
      });
      if (block) batch.delete(doc(db, `calendarBlocks/${id}`));
      if (lock) batch.delete(doc(db, 'renterLocks/renter4'));
      if (refund > 0) {
        batch.set(
          doc(collection(db, 'transactions')),
          ledgerMap(id, 'refund', 'veloce', 'renter', refund, serverTimestamp()),
        );
      }
      audit(db, batch, uid, id, 'x', 'cancelled');
      return batch.commit();
    };

    it('lets the renter cancel a pending request (block delete of a missing doc is fine)', async () => {
      await s.seed({ 'bookings/b-p': bookingMap() });
      await assertSucceeds(cancel(RENTER, 'b-p', { lock: false }));
    });

    it('rejects the owner cancelling a pending request (decline instead, R2R-12)', async () => {
      await s.seed({ 'bookings/b-p': bookingMap() });
      await assertFails(cancel(OWNER, 'b-p', { lock: false }));
    });

    it('lets either party cancel an approved booking and frees the block and lock', async () => {
      for (const uid of [RENTER, OWNER]) {
        await s.environment.clearFirestore();
        await seedBase();
        await s.seed({
          'bookings/b-a': bookingMap({ status: 'approved' }),
          'calendarBlocks/b-a': { bookingId: 'b-a', vehicleId: 'car-1' },
          'renterLocks/renter4': { bookingId: 'b-a', createdAt: new Date() },
        });
        await assertSucceeds(cancel(uid, 'b-a'));
      }
    });

    it('cancels a confirmed booking with the refund row (totalPayable)', async () => {
      await s.seed({
        'bookings/b-c': bookingMap({ status: 'confirmed' }),
        'calendarBlocks/b-c': { bookingId: 'b-c', vehicleId: 'car-1' },
      });
      await assertSucceeds(cancel(RENTER, 'b-c', { refund: 190000, lock: false }));
    });

    it('rejects a refund that is not totalPayable or for an unpaid booking', async () => {
      await s.seed({
        'bookings/b-c': bookingMap({ status: 'confirmed' }),
        'bookings/b-a': bookingMap({ status: 'approved' }),
      });
      await assertFails(cancel(RENTER, 'b-c', { refund: 100, lock: false }));
      await assertFails(cancel(RENTER, 'b-a', { refund: 190000, lock: false }));
    });

    it('rejects a block delete by an outsider and a lock delete by an outsider', async () => {
      await s.seed({
        'bookings/b-a': bookingMap({ status: 'approved' }),
        'calendarBlocks/b-a': { bookingId: 'b-a', vehicleId: 'car-1' },
        'renterLocks/renter4': { bookingId: 'b-a', createdAt: new Date() },
      });
      await assertFails(deleteDoc(doc(dbFor(OUTSIDER), 'calendarBlocks/b-a')));
      await assertFails(deleteDoc(doc(dbFor(OUTSIDER), 'renterLocks/renter4')));
      // A party cannot drop them while the booking stays live.
      await assertFails(deleteDoc(doc(dbFor(RENTER), 'calendarBlocks/b-a')));
      await assertFails(deleteDoc(doc(dbFor(RENTER), 'renterLocks/renter4')));
    });

    it('rejects updating a calendar block', async () => {
      await s.seed({
        'bookings/b-a': bookingMap({ status: 'approved' }),
        'calendarBlocks/b-a': { bookingId: 'b-a', vehicleId: 'car-1' },
      });
      await assertFails(updateDoc(doc(dbFor(OWNER), 'calendarBlocks/b-a'), { vehicleId: 'x' }));
    });
  });

  describe('expire', () => {
    const expire = (uid, id, { lock = false } = {}) => {
      const db = dbFor(uid);
      const batch = writeBatch(db);
      batch.update(doc(db, `bookings/${id}`), {
        status: 'expired',
        reason: 'Payment was not made in time.',
        updatedAt: serverTimestamp(),
      });
      batch.delete(doc(db, `calendarBlocks/${id}`));
      if (lock) batch.delete(doc(db, 'renterLocks/renter4'));
      audit(db, batch, uid, id, 'x', 'expired');
      for (const u of [RENTER, OWNER]) note(db, batch, u, id);
      return batch.commit();
    };

    it('lets either party expire a pending booking', async () => {
      await s.seed({ 'bookings/b-p': bookingMap() });
      await assertSucceeds(expire(OWNER, 'b-p'));
      await s.seed({ 'bookings/b-p2': bookingMap() });
      await assertSucceeds(expire(RENTER, 'b-p2'));
    });

    it('expires an approved booking and deletes its lock and block', async () => {
      await s.seed({
        'bookings/b-a': bookingMap({ status: 'approved' }),
        'calendarBlocks/b-a': { bookingId: 'b-a', vehicleId: 'car-1' },
        'renterLocks/renter4': { bookingId: 'b-a', createdAt: new Date() },
      });
      await assertSucceeds(expire(RENTER, 'b-a', { lock: true }));
    });

    it('rejects an outsider and a client-date updatedAt', async () => {
      await s.seed({ 'bookings/b-p': bookingMap() });
      await assertFails(expire(OUTSIDER, 'b-p'));
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'bookings/b-p'), {
          status: 'expired',
          reason: 'x',
          updatedAt: new Date(),
        }),
      );
    });

    it('rejects expiring a confirmed booking', async () => {
      await s.seed({ 'bookings/b-c': bookingMap({ status: 'confirmed' }) });
      await assertFails(expire(RENTER, 'b-c'));
    });
  });

  describe('pay, agreement ack and contact', () => {
    beforeEach(() =>
      s.seed({
        'bookings/b-a': bookingMap({ status: 'approved' }),
        'bookings/b-a/private/owner': { bookingId: 'b-a', phone: '1', email: 'o' },
        'bookings/b-a/private/renter': { bookingId: 'b-a', phone: '2', email: 'r' },
      }),
    );

    const pay = (uid, amount = 190000) => {
      const db = dbFor(uid);
      const batch = writeBatch(db);
      batch.update(doc(db, 'bookings/b-a'), {
        status: 'confirmed',
        updatedAt: serverTimestamp(),
      });
      batch.set(
        doc(collection(db, 'transactions')),
        ledgerMap('b-a', 'charge', 'renter', 'veloce', amount, serverTimestamp(), {
          reference: 'MOMO-1',
        }),
      );
      audit(db, batch, uid, 'b-a', 'approved', 'confirmed');
      note(db, batch, OWNER, 'b-a');
      return batch.commit();
    };

    it('commits confirmed + charge row for the renter', async () => {
      await assertSucceeds(pay(RENTER));
    });

    it('rejects the owner paying, a wrong amount, or an outsider', async () => {
      await assertFails(pay(OWNER));
      await assertFails(pay(RENTER, 1));
      await assertFails(pay(OUTSIDER));
    });

    it('keeps the counterparty contact locked until payment, then opens it', async () => {
      await assertSucceeds(getDoc(doc(dbFor(RENTER), 'bookings/b-a/private/renter')));
      await assertSucceeds(getDoc(doc(dbFor(OWNER), 'bookings/b-a/private/owner')));
      await assertFails(getDoc(doc(dbFor(RENTER), 'bookings/b-a/private/owner')));
      await assertFails(getDoc(doc(dbFor(OWNER), 'bookings/b-a/private/renter')));
      await assertSucceeds(pay(RENTER));
      await assertSucceeds(getDoc(doc(dbFor(RENTER), 'bookings/b-a/private/owner')));
      await assertSucceeds(getDoc(doc(dbFor(OWNER), 'bookings/b-a/private/renter')));
      await assertFails(getDoc(doc(dbFor(OUTSIDER), 'bookings/b-a/private/owner')));
    });

    it('lets the renter acknowledge the agreement with server times', async () => {
      await assertSucceeds(
        updateDoc(doc(dbFor(RENTER), 'bookings/b-a'), {
          agreementAckAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('rejects an acknowledgement with a client date, by the owner, or bundled', async () => {
      const ref = (uid) => doc(dbFor(uid), 'bookings/b-a');
      await assertFails(
        updateDoc(ref(RENTER), { agreementAckAt: new Date(), updatedAt: serverTimestamp() }),
      );
      await assertFails(
        updateDoc(ref(OWNER), { agreementAckAt: serverTimestamp(), updatedAt: serverTimestamp() }),
      );
      await assertFails(
        updateDoc(ref(RENTER), {
          agreementAckAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
          rentalFee: 1,
        }),
      );
    });

    it('lets the renter acknowledge when confirmed too', async () => {
      await s.seed({ 'bookings/b-c': bookingMap({ status: 'confirmed' }) });
      await assertSucceeds(
        updateDoc(doc(dbFor(RENTER), 'bookings/b-c'), {
          agreementAckAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
    });
  });

  it('active to return removes the renter lock in the same batch', async () => {
    await s.seed({
      'bookings/b-act': bookingMap({ status: 'active' }),
      'renterLocks/renter4': { bookingId: 'b-act', createdAt: new Date() },
    });
    const db = dbFor(RENTER);
    const batch = writeBatch(db);
    batch.update(doc(db, 'bookings/b-act'), {
      status: 'return',
      returnedAt: ts(),
      updatedAt: ts(),
    });
    batch.delete(doc(db, 'renterLocks/renter4'));
    await assertSucceeds(batch.commit());
  });
});

describe('client shapes: caution claims (phase 5)', () => {
  s.useEnvironment();
  beforeEach(async () => {
    await seedBase();
    await s.seed({ 'bookings/b-ret': bookingMap({ status: 'return', returnedAt: new Date() }) });
  });

  const claimRef = (uid) => doc(dbFor(uid), 'cautionClaims/b-ret');
  const bookingRef = (uid) => doc(dbFor(uid), 'bookings/b-ret');

  // submitClaim: claim set + booking return -> review.
  const submit = (uid = OWNER) => {
    const batch = writeBatch(dbFor(uid));
    batch.set(claimRef(uid), claimMap());
    batch.update(bookingRef(uid), {
      status: 'review',
      cautionDecision: 'claim',
      updatedAt: ts(),
    });
    return batch.commit();
  };

  const settle = (uid, claim, rows, extra = {}) => {
    const db = dbFor(uid);
    const batch = writeBatch(db);
    batch.set(claimRef(uid), claim);
    batch.update(bookingRef(uid), {
      status: 'completed',
      lateDays: 0,
      lateFee: 0,
      completedAt: ts(),
      updatedAt: ts(),
      ...extra,
    });
    for (const [type, to, amount] of rows) {
      batch.set(
        doc(collection(db, 'transactions')),
        ledgerMap('b-ret', type, 'veloce', to, amount, serverTimestamp(), {
          reference: 'b-ret',
        }),
      );
    }
    for (const u of [RENTER, OWNER]) {
      batch.update(doc(db, `users/${u}`), { completedCount: increment(1) });
    }
    return batch.commit();
  };

  it('lets the owner submit the claim from the real wire map', async () => {
    await assertSucceeds(submit());
  });

  it('rejects submit by the renter or an outsider, and an above-caution claim', async () => {
    await assertFails(submit(RENTER));
    await assertFails(submit(OUTSIDER));
    await assertFails(
      setDoc(claimRef(OWNER), claimMap({ originalAmount: 100001, currentAmount: 100001 })),
    );
  });

  it('rejects a claim map without bookingId (the R2R-01 shape)', async () => {
    const { bookingId, ...legacy } = claimMap();
    await assertFails(setDoc(claimRef(OWNER), legacy));
  });

  describe('after submit', () => {
    beforeEach(submit);

    it('lets the renter dispute (claim set + booking updatedAt)', async () => {
      const batch = writeBatch(dbFor(RENTER));
      batch.set(
        claimRef(RENTER),
        claimMap({
          renterResponse: 'disputed',
          history: [...claimMap().history, { amount: 50000, reason: 'r', at: ts(), response: 'disputed' }],
        }),
      );
      batch.update(bookingRef(RENTER), { updatedAt: ts() });
      await assertSucceeds(batch.commit());
    });

    it('lets the owner re-claim a lower amount, but not raise the original', async () => {
      await assertSucceeds(
        setDoc(claimRef(OWNER), claimMap({ currentAmount: 30000 })),
      );
      await assertFails(
        setDoc(claimRef(OWNER), claimMap({ originalAmount: 60000, currentAmount: 60000 })),
      );
      await assertFails(
        setDoc(claimRef(OWNER), claimMap({ currentAmount: 50001 })),
      );
    });

    it('settles an agreed claim: claim settled, deduction and refund rows, counts', async () => {
      await assertSucceeds(
        settle(
          RENTER,
          claimMap({ renterResponse: 'agreed', status: 'settled' }),
          [
            ['claim_deduction', 'owner', 50000],
            ['refund', 'renter', 50000],
          ],
        ),
      );
    });

    it('refunds after a dispute: claim refunded, refund row of the caution', async () => {
      await setDoc(claimRef(RENTER), claimMap({ renterResponse: 'disputed' }));
      await assertSucceeds(
        settle(OWNER, claimMap({ renterResponse: 'disputed', status: 'refunded' }), [
          ['refund', 'renter', 100000],
        ]),
      );
    });

    it('rejects a settlement row above the caution', async () => {
      await assertFails(
        settle(RENTER, claimMap({ status: 'settled' }), [['claim_deduction', 'owner', 100001]]),
      );
    });

    it('lets only parties read and rejects an outsider update', async () => {
      await assertSucceeds(getDoc(claimRef(RENTER)));
      await assertFails(getDoc(claimRef(OUTSIDER)));
      await assertFails(
        setDoc(claimRef(OUTSIDER), claimMap({ renterResponse: 'agreed' })),
      );
    });
  });

  it('settles the no-issue path with late fee and refund rows', async () => {
    const db = dbFor(RENTER);
    const batch = writeBatch(db);
    batch.update(doc(db, 'bookings/b-ret'), {
      status: 'completed',
      lateDays: 1,
      lateFee: 9000,
      completedAt: ts(),
      updatedAt: ts(),
      cautionDecision: 'refund',
      renterOutcomeAckAt: ts(),
    });
    batch.set(
      doc(collection(db, 'transactions')),
      ledgerMap('b-ret', 'late_fee', 'veloce', 'owner', 9000, serverTimestamp()),
    );
    batch.set(
      doc(collection(db, 'transactions')),
      ledgerMap('b-ret', 'refund', 'veloce', 'renter', 91000, serverTimestamp()),
    );
    batch.update(doc(db, 'users/renter4'), { completedCount: increment(1) });
    batch.update(doc(db, 'users/owner1'), { completedCount: increment(1) });
    await assertSucceeds(batch.commit());
  });
});

describe('client shapes: list queries', () => {
  s.useEnvironment();
  beforeEach(async () => {
    await seedBase();
    await s.seed({
      'bookings/b-1': bookingMap({ status: 'pending' }),
      'bookings/b-done': bookingMap({ status: 'completed' }),
      'bookings/b-x': bookingMap({ renterId: OUTSIDER, status: 'pending' }),
      'repairExpenses/r1': {
        ownerId: OWNER,
        bookingId: 'b-done',
        amount: 1000,
        description: 'd',
        receiptUrl: 'u',
      },
      'transactions/t1': ledgerMap('b-done', 'charge', 'renter', 'veloce', 190000, new Date()),
      'notifications/n1': {
        userId: RENTER,
        read: false,
        type: 'x',
        createdAt: new Date(),
      },
      'reviews/b-done_renter4_user': {
        bookingId: 'b-done',
        authorId: RENTER,
        subjectType: 'user',
        subjectId: OWNER,
        stars: 5,
        createdAt: new Date(),
      },
      'calendarBlocks/b-1': {
        bookingId: 'b-1',
        vehicleId: 'car-1',
        startDate: new Date(),
        endDate: new Date('2030-01-01T00:00:00Z'),
      },
    });
  });

  const q = (uid, col, ...clauses) =>
    getDocs(query(collection(dbFor(uid), col), ...clauses));
  const w = where;

  it('bookings by renterId and ownerId, ordered by createdAt (watchMyBookings)', async () => {
    await assertSucceeds(q(RENTER, 'bookings', w('renterId', '==', RENTER), orderBy('createdAt', 'desc')));
    await assertSucceeds(q(OWNER, 'bookings', w('ownerId', '==', OWNER), orderBy('createdAt', 'desc')));
    await assertFails(q(OUTSIDER, 'bookings', w('renterId', '==', RENTER)));
    await assertFails(q(OUTSIDER, 'bookings', w('ownerId', '==', OWNER)));
    await assertFails(q(RENTER, 'bookings', w('ownerId', '==', OWNER)));
  });

  it('an unfiltered bookings list fails for everyone', async () => {
    await assertFails(q(OWNER, 'bookings'));
  });

  it('bookings by vehicleId + ownerId (bookingsOf)', async () => {
    await assertSucceeds(q(OWNER, 'bookings', w('vehicleId', '==', 'car-1'), w('ownerId', '==', OWNER)));
    await assertFails(q(OUTSIDER, 'bookings', w('vehicleId', '==', 'car-1'), w('ownerId', '==', OWNER)));
    await assertFails(q(OWNER, 'bookings', w('vehicleId', '==', 'car-1')));
  });

  it('the approve-overlap query (ownerId, vehicleId, status, startDate)', async () => {
    const overlap = (uid) =>
      q(
        uid,
        'bookings',
        w('ownerId', '==', OWNER),
        w('vehicleId', '==', 'car-1'),
        w('status', '==', 'pending'),
        w('startDate', '<', ts(new Date('2027-01-01T00:00:00Z'))),
        orderBy('startDate'),
      );
    await assertSucceeds(overlap(OWNER));
    await assertFails(overlap(OUTSIDER));
    // The R2R-03 shape without ownerId cannot be proven by the rules.
    await assertFails(
      q(OWNER, 'bookings', w('vehicleId', '==', 'car-1'), w('status', '==', 'pending')),
    );
  });

  it('pending-review checker: bookings by party + completed', async () => {
    await assertSucceeds(q(RENTER, 'bookings', w('renterId', '==', RENTER), w('status', '==', 'completed')));
    await assertSucceeds(q(OWNER, 'bookings', w('ownerId', '==', OWNER), w('status', '==', 'completed')));
    await assertFails(q(OUTSIDER, 'bookings', w('renterId', '==', RENTER), w('status', '==', 'completed')));
  });

  it('repairExpenses by ownerId and bookingId + ownerId', async () => {
    await assertSucceeds(q(OWNER, 'repairExpenses', w('ownerId', '==', OWNER)));
    await assertSucceeds(q(OWNER, 'repairExpenses', w('bookingId', '==', 'b-done'), w('ownerId', '==', OWNER)));
    await assertFails(q(OUTSIDER, 'repairExpenses', w('ownerId', '==', OWNER)));
    await assertFails(q(RENTER, 'repairExpenses', w('bookingId', '==', 'b-done')));
  });

  it('transactions by ownerId (+ vehicleId) and by renterId ordered by at', async () => {
    await assertSucceeds(q(OWNER, 'transactions', w('ownerId', '==', OWNER)));
    await assertSucceeds(q(OWNER, 'transactions', w('ownerId', '==', OWNER), w('vehicleId', '==', 'car-1')));
    await assertSucceeds(q(RENTER, 'transactions', w('renterId', '==', RENTER), orderBy('at', 'desc')));
    await assertFails(q(OUTSIDER, 'transactions', w('ownerId', '==', OWNER)));
    await assertFails(q(OUTSIDER, 'transactions', w('renterId', '==', RENTER)));
  });

  it('notifications by userId (ordered, and unread only)', async () => {
    await assertSucceeds(q(RENTER, 'notifications', w('userId', '==', RENTER), orderBy('createdAt', 'desc')));
    await assertSucceeds(q(RENTER, 'notifications', w('userId', '==', RENTER), w('read', '==', false)));
    await assertFails(q(OUTSIDER, 'notifications', w('userId', '==', RENTER)));
  });

  it('reviews by subject, author and booking for any signed-in user, not anonymous', async () => {
    await assertSucceeds(q(OUTSIDER, 'reviews', w('subjectType', '==', 'user'), w('subjectId', '==', OWNER), orderBy('createdAt', 'desc')));
    await assertSucceeds(q(OUTSIDER, 'reviews', w('authorId', '==', RENTER), orderBy('createdAt', 'desc')));
    await assertSucceeds(q(OUTSIDER, 'reviews', w('bookingId', '==', 'b-done')));
    await assertFails(getDocs(query(collection(s.anon(), 'reviews'), w('bookingId', '==', 'b-done'))));
  });

  it('calendarBlocks by vehicleId (+ endDate), signed in only', async () => {
    await assertSucceeds(q(OUTSIDER, 'calendarBlocks', w('vehicleId', '==', 'car-1'), w('endDate', '>', ts())));
    await assertSucceeds(q(OUTSIDER, 'calendarBlocks', w('vehicleId', '==', 'car-1')));
    await assertFails(getDocs(query(collection(s.anon(), 'calendarBlocks'), w('vehicleId', '==', 'car-1'))));
  });

  it('vehicle search (published, docsValidUntil, neighbourhood) and my cars', async () => {
    await assertSucceeds(
      q(OUTSIDER, 'vehicles', w('status', '==', 'published'), w('docsValidUntil', '>=', ts()), w('neighbourhood', '==', 'Kacyiru')),
    );
    await assertSucceeds(q(OWNER, 'vehicles', w('ownerId', '==', OWNER), orderBy('createdAt', 'desc')));
    await assertFails(
      getDocs(query(collection(s.anon(), 'vehicles'), w('status', '==', 'published'))),
    );
  });

  it('a single booking get: parties yes, outsider no', async () => {
    await assertSucceeds(getDoc(doc(dbFor(RENTER), 'bookings/b-1')));
    await assertSucceeds(getDoc(doc(dbFor(OWNER), 'bookings/b-1')));
    await assertFails(getDoc(doc(dbFor(OUTSIDER), 'bookings/b-1')));
  });
});

// ---- account eraser: a port of FirestoreAccountEraser._plan/_commit ----
async function eraseAll(uid) {
  const db = dbFor(uid);
  const max = 450;
  const where_ = async (col, field, value) =>
    (await getDocs(query(collection(db, col), where(field, '==', value)))).docs;
  const list = async (path) => (await getDocs(collection(db, path))).docs;
  const batches = [];
  const seen = new Set();
  const loose = [];

  function addUnit(before, withParent, parent) {
    const early = before.filter((p) => seen.add(p));
    const last = [...withParent.filter((p) => seen.add(p)), parent];
    let start = 0;
    while (early.length - start + last.length > max) {
      const take = Math.min(early.length - start, max);
      batches.push(early.slice(start, start + take));
      start += take;
    }
    batches.push([...early.slice(start), ...last]);
  }

  const vehicles = await where_('vehicles', 'ownerId', uid);
  const bookings = new Map();
  for (const field of ['renterId', 'ownerId']) {
    for (const d of await where_('bookings', field, uid)) bookings.set(d.id, d);
  }
  for (const b of bookings.values()) {
    const checklists = [];
    for (const sub of ['checklistEntries', 'checklistMedia']) {
      for (const d of await list(`${b.ref.path}/${sub}`)) checklists.push(d.ref.path);
    }
    const renterId = b.data().renterId;
    const mine = renterId === uid ? 'renter' : 'owner';
    const claim = await getDoc(doc(db, `cautionClaims/${b.id}`));
    const lock = await getDoc(doc(db, `renterLocks/${renterId}`));
    addUnit(
      checklists,
      [
        `${b.ref.path}/private/${mine}`,
        `calendarBlocks/${b.id}`,
        ...(claim.exists() ? [claim.ref.path] : []),
        ...(lock.exists() && lock.data().bookingId === b.id ? [lock.ref.path] : []),
      ],
      b.ref.path,
    );
  }
  for (const v of vehicles) {
    const before = [];
    for (const sub of ['photos', 'documents']) {
      for (const d of await list(`${v.ref.path}/${sub}`)) before.push(d.ref.path);
    }
    for (const d of await where_('reviews', 'subjectId', v.id)) before.push(d.ref.path);
    addUnit(before, [], v.ref.path);
  }
  for (const [col, field] of [
    ['transactions', 'ownerId'],
    ['transactions', 'renterId'],
    ['repairExpenses', 'ownerId'],
    ['notifications', 'userId'],
    ['reviews', 'authorId'],
    ['reviews', 'subjectId'],
  ]) {
    for (const d of await where_(col, field, uid)) {
      if (seen.add(d.ref.path)) loose.push(d.ref.path);
    }
  }
  for (const sub of ['favourites', 'private']) {
    for (const d of await list(`users/${uid}/${sub}`)) {
      if (seen.add(d.ref.path)) loose.push(d.ref.path);
    }
  }
  for (let i = 0; i < loose.length; i += max) batches.push(loose.slice(i, i + max));
  batches.push([`users/${uid}`]);

  for (const paths of batches) {
    const batch = writeBatch(db);
    for (const p of paths) batch.delete(doc(db, p));
    await batch.commit();
  }
  return batches.length;
}

describe('client shapes: account eraser', () => {
  s.useEnvironment();

  const claimDoc = claimMap({ bookingId: 'b-rev' });
  const world = () => ({
    'users/owner1': userDoc('owner'),
    'users/renter4': userDoc('renter'),
    'users/renter4/private/payout': { momo: '0788' },
    'users/renter4/favourites/car-1': { userId: RENTER },
    'users/renter5': userDoc('renter'),
    'vehicles/car-1': { ownerId: OWNER, status: 'published' },
    'vehicles/car-1/photos/p1': { url: 'a' },
    'vehicles/car-1/documents/insurance': { url: 'b' },
    'bookings/b-act': bookingMap({ status: 'active' }),
    'bookings/b-act/checklistEntries/e1': { side: 'owner' },
    'bookings/b-act/checklistMedia/m1': { side: 'owner' },
    'bookings/b-act/private/renter': { bookingId: 'b-act' },
    'bookings/b-act/private/owner': { bookingId: 'b-act' },
    'calendarBlocks/b-act': { bookingId: 'b-act', vehicleId: 'car-1' },
    'bookings/b-rev': bookingMap({ status: 'review' }),
    'cautionClaims/b-rev': claimDoc,
    'bookings/b-appr': bookingMap({ status: 'approved' }),
    'bookings/b-appr/private/owner': { bookingId: 'b-appr' },
    'renterLocks/renter4': { bookingId: 'b-appr', createdAt: new Date() },
    'calendarBlocks/b-appr': { bookingId: 'b-appr', vehicleId: 'car-1' },
    'bookings/b-done': bookingMap({ status: 'completed' }),
    'bookings/b-other': bookingMap({ status: 'pending', renterId: OUTSIDER }),
    'transactions/t1': ledgerMap('b-done', 'charge', 'renter', 'veloce', 190000, new Date()),
    'transactions/t2': ledgerMap('b-act', 'charge', 'renter', 'veloce', 190000, new Date()),
    'repairExpenses/r1': { ownerId: OWNER, bookingId: 'b-rev', amount: 5, description: 'd', receiptUrl: 'u' },
    'notifications/n1': { userId: RENTER, read: false },
    'notifications/n2': { userId: OWNER, read: false },
    'reviews/b-done_renter4_user': { bookingId: 'b-done', authorId: RENTER, subjectType: 'user', subjectId: OWNER, stars: 5 },
    'reviews/b-done_owner1_user': { bookingId: 'b-done', authorId: OWNER, subjectType: 'user', subjectId: RENTER, stars: 4 },
    'reviews/b-done_renter4_vehicle': { bookingId: 'b-done', authorId: RENTER, subjectType: 'vehicle', subjectId: 'car-1', stars: 5 },
    'reviews/y_renter5_vehicle': { bookingId: 'y', authorId: OUTSIDER, subjectType: 'vehicle', subjectId: 'car-1', stars: 3 },
  });

  const exists = (p) => s.admin(async (db) => (await getDoc(doc(db, p))).exists());
  const count = (col, field, value) =>
    s.admin(async (db) =>
      (await getDocs(query(collection(db, col), where(field, '==', value)))).size,
    );

  beforeEach(() => s.seed(world()));

  it('erases a renter with an active booking, a claim, a lock, ledger rows and reviews', async () => {
    await assertSucceeds(eraseAll(RENTER));
    {
      for (const p of [
        'users/renter4', 'users/renter4/private/payout', 'users/renter4/favourites/car-1',
        'bookings/b-act', 'bookings/b-act/checklistEntries/e1', 'bookings/b-act/checklistMedia/m1',
        'bookings/b-act/private/renter', 'calendarBlocks/b-act', 'bookings/b-rev', 'cautionClaims/b-rev',
        'bookings/b-appr', 'renterLocks/renter4', 'calendarBlocks/b-appr', 'bookings/b-done',
        'transactions/t1', 'transactions/t2', 'notifications/n1',
        'reviews/b-done_renter4_user', 'reviews/b-done_owner1_user', 'reviews/b-done_renter4_vehicle',
      ]) {
        if (await exists(p)) throw new Error(`${p} still exists`);
      }
    }
    // What belongs to others stays.
    for (const p of ['users/owner1', 'users/renter5', 'vehicles/car-1', 'bookings/b-other', 'notifications/n2', 'reviews/y_renter5_vehicle']) {
      if (!(await exists(p))) throw new Error(`${p} was wrongly deleted`);
    }
  });

  it('erases an owner: cars with photos, documents and reviews, their bookings, claim, repairs', async () => {
    await assertSucceeds(eraseAll(OWNER));
    for (const p of [
      'users/owner1', 'vehicles/car-1', 'vehicles/car-1/photos/p1', 'vehicles/car-1/documents/insurance',
      'bookings/b-act', 'bookings/b-rev', 'bookings/b-appr', 'bookings/b-done', 'bookings/b-other',
      'cautionClaims/b-rev', 'calendarBlocks/b-act', 'calendarBlocks/b-appr', 'renterLocks/renter4',
      'repairExpenses/r1', 'transactions/t1', 'notifications/n2',
      'reviews/b-done_renter4_vehicle', 'reviews/y_renter5_vehicle', 'reviews/b-done_owner1_user',
    ]) {
      if (await exists(p)) throw new Error(`${p} still exists`);
    }
    if (!(await exists('users/renter5'))) throw new Error('renter5 deleted');
  });

  it('erases the renter first and then the owner, and can run twice', async () => {
    await assertSucceeds(eraseAll(RENTER));
    await assertSucceeds(eraseAll(OWNER));
    await assertSucceeds(eraseAll(RENTER));
    if ((await count('bookings', 'ownerId', OWNER)) !== 0) throw new Error('bookings left');
  });

  it('erases a user with more than 20 bookings and ledger rows (access-call limit)', async () => {
    const many = {};
    for (let i = 0; i < 30; i += 1) {
      many[`bookings/m${i}`] = bookingMap({ status: i % 2 ? 'active' : 'completed' });
      many[`calendarBlocks/m${i}`] = { bookingId: `m${i}`, vehicleId: 'car-1' };
      many[`transactions/mt${i}`] = ledgerMap(`m${i}`, 'charge', 'renter', 'veloce', 1, new Date());
    }
    await s.seed(many);
    await assertSucceeds(eraseAll(RENTER));
    if ((await count('transactions', 'renterId', RENTER)) !== 0) throw new Error('ledger left');
  });

  it('rejects an outsider erasing the same documents', async () => {
    const db = dbFor(OUTSIDER);
    await assertFails(deleteDoc(doc(db, 'bookings/b-act')));
    await assertFails(deleteDoc(doc(db, 'users/renter4')));
    await assertFails(deleteDoc(doc(db, 'cautionClaims/b-rev')));
    await assertFails(deleteDoc(doc(db, 'transactions/t1')));
    await assertFails(deleteDoc(doc(db, 'renterLocks/renter4')));
    await assertFails(deleteDoc(doc(db, 'vehicles/car-1')));
    await assertFails(deleteDoc(doc(db, 'notifications/n1')));
  });
});

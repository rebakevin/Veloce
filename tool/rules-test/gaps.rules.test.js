/* eslint-disable no-console */
// Round-2 test gaps (R2R-T3/T4/T5/T-at): create rules, negatives, deletes.
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  deleteDoc,
  doc,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} = require('firebase/firestore');
const s = require('./support');
const { OWNER, RENTER, OUTSIDER, bookingMap, dbFor, hours, ledgerMap } = s;

const userDoc = (role) => ({
  role,
  ratingAvg: 0,
  ratingCount: 0,
  completedCount: 0,
});

async function seedBase() {
  await s.seed({
    'users/owner1': userDoc('owner'),
    'users/renter4': userDoc('renter'),
    'users/renter5': userDoc('renter'),
    'vehicles/car-1': { ownerId: OWNER, status: 'published' },
    'vehicles/car-paused': { ownerId: OWNER, status: 'paused' },
    'vehicles/car-own': { ownerId: RENTER, status: 'published' },
  });
}

describe('gaps', () => {
  s.useEnvironment();
  beforeEach(seedBase);

  describe('users create and completedCount', () => {
    const fresh = (overrides = {}) => ({
      name: 'New',
      role: 'renter',
      ratingAvg: 0,
      ratingCount: 0,
      completedCount: 0,
      createdAt: serverTimestamp(),
      ...overrides,
    });

    it('lets a user create their own profile with zeroed aggregates', async () => {
      await assertSucceeds(setDoc(doc(dbFor('new1'), 'users/new1'), fresh()));
      await assertSucceeds(
        setDoc(doc(dbFor('new2'), 'users/new2'), fresh({ role: 'owner' })),
      );
    });

    it('rejects a bad role, non-zero or missing aggregates, or another uid', async () => {
      const ref = (uid) => doc(dbFor('new1'), `users/${uid}`);
      await assertFails(setDoc(ref('new1'), fresh({ role: 'admin' })));
      await assertFails(setDoc(ref('new1'), fresh({ ratingCount: 3 })));
      await assertFails(setDoc(ref('new1'), fresh({ ratingAvg: 5 })));
      await assertFails(setDoc(ref('new1'), fresh({ completedCount: 9 })));
      const { completedCount, ...missing } = fresh();
      await assertFails(setDoc(ref('new1'), missing));
      await assertFails(setDoc(ref('someone-else'), fresh()));
    });

    it('lets self and another user add exactly one completedCount', async () => {
      await assertSucceeds(
        updateDoc(doc(dbFor(RENTER), 'users/renter4'), {
          completedCount: increment(1),
        }),
      );
      await assertSucceeds(
        updateDoc(doc(dbFor(RENTER), 'users/owner1'), {
          completedCount: increment(1),
        }),
      );
    });

    it('commits the completer batch: both counts +1 in one write', async () => {
      const db = dbFor(OWNER);
      const batch = writeBatch(db);
      batch.update(doc(db, 'users/owner1'), { completedCount: increment(1) });
      batch.update(doc(db, 'users/renter4'), { completedCount: increment(1) });
      await assertSucceeds(batch.commit());
    });

    it('rejects +2, a jump, a decrement, or anonymous', async () => {
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'users/renter4'), {
          completedCount: increment(2),
        }),
      );
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'users/owner1'), {
          completedCount: increment(2),
        }),
      );
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'users/owner1'), { completedCount: 10 }),
      );
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'users/owner1'), {
          completedCount: increment(-1),
        }),
      );
      await assertFails(
        updateDoc(doc(s.anon(), 'users/owner1'), {
          completedCount: increment(1),
        }),
      );
    });

    it('rejects +1 completedCount bundled with another field', async () => {
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'users/owner1'), {
          completedCount: increment(1),
          name: 'hijack',
        }),
      );
    });

    it('rejects changing role or verified on yourself', async () => {
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'users/renter4'), { role: 'owner' }),
      );
      await assertFails(
        updateDoc(doc(dbFor(RENTER), 'users/renter4'), { verified: true }),
      );
    });
  });

  describe('vehicles create and removal', () => {
    const car = (overrides = {}) => ({
      ownerId: RENTER,
      status: 'published',
      ratingAvg: 0,
      ratingCount: 0,
      make: 'Toyota',
      ...overrides,
    });

    it('lets a user create a published or paused car they own', async () => {
      await assertSucceeds(setDoc(doc(dbFor(RENTER), 'vehicles/n1'), car()));
      await assertSucceeds(
        setDoc(doc(dbFor(RENTER), 'vehicles/n2'), car({ status: 'paused' })),
      );
    });

    it('rejects a bad status, ratings, owner, or missing rating fields', async () => {
      const ref = doc(dbFor(RENTER), 'vehicles/n1');
      await assertFails(setDoc(ref, car({ status: 'archived' })));
      await assertFails(setDoc(ref, car({ ratingCount: 2 })));
      await assertFails(setDoc(ref, car({ ratingAvg: 4 })));
      await assertFails(setDoc(ref, car({ ownerId: OWNER })));
      const { ratingCount, ...missing } = car();
      await assertFails(setDoc(ref, missing));
      await assertFails(setDoc(doc(s.anon(), 'vehicles/n1'), car()));
    });

    it('creates a car with its photo and document in one batch', async () => {
      const db = dbFor(RENTER);
      const batch = writeBatch(db);
      batch.set(doc(db, 'vehicles/n1'), car());
      batch.set(doc(db, 'vehicles/n1/photos/p1'), { url: 'u', order: 0 });
      batch.set(doc(db, 'vehicles/n1/documents/insurance'), { url: 'u' });
      await assertSucceeds(batch.commit());
    });

    describe('removal batch', () => {
      beforeEach(() =>
        s.seed({
          'vehicles/car-del': { ownerId: OWNER, status: 'paused' },
          'vehicles/car-del/photos/p1': { url: 'a' },
          'vehicles/car-del/photos/p2': { url: 'b' },
          'vehicles/car-del/documents/insurance': { url: 'c' },
        }),
      );

      const removal = (uid) => {
        const db = dbFor(uid);
        const batch = writeBatch(db);
        batch.delete(doc(db, 'vehicles/car-del/photos/p1'));
        batch.delete(doc(db, 'vehicles/car-del/photos/p2'));
        batch.delete(doc(db, 'vehicles/car-del/documents/insurance'));
        batch.delete(doc(db, 'vehicles/car-del'));
        return batch.commit();
      };

      it('lets the owner delete the car, photos and documents together', async () => {
        await assertSucceeds(removal(OWNER));
      });

      it('rejects the same batch by a non-owner', async () => {
        await assertFails(removal(RENTER));
      });

      it('rejects a non-owner deleting only a photo or the car', async () => {
        await assertFails(deleteDoc(doc(dbFor(RENTER), 'vehicles/car-del/photos/p1')));
        await assertFails(deleteDoc(doc(dbFor(RENTER), 'vehicles/car-del')));
      });

      it('hides the documents from a non-owner', async () => {
        const { getDoc } = require('firebase/firestore');
        await assertSucceeds(getDoc(doc(dbFor(OWNER), 'vehicles/car-del/documents/insurance')));
        await assertFails(getDoc(doc(dbFor(RENTER), 'vehicles/car-del/documents/insurance')));
        await assertSucceeds(getDoc(doc(dbFor(RENTER), 'vehicles/car-del/photos/p1')));
      });
    });
  });

  describe('booking create negatives', () => {
    let n = 0;
    const create = (overrides, uid = RENTER) => {
      const data = bookingMap(overrides);
      for (const key of Object.keys(data)) {
        if (data[key] === undefined) delete data[key];
      }
      return setDoc(doc(dbFor(uid), `bookings/b-new-${n++}`), data);
    };

    it('accepts the real shape (control)', async () => {
      await assertSucceeds(create({}));
      await assertSucceeds(create({ expiresAt: hours(24.9) }));
    });

    it('rejects an unpublished or missing car', async () => {
      await assertFails(create({ vehicleId: 'car-paused' }));
      await assertFails(create({ vehicleId: 'car-missing' }));
    });

    it('rejects booking your own car', async () => {
      await assertFails(
        create({ vehicleId: 'car-own', ownerId: RENTER }),
      );
    });

    it('rejects rentalFee != days * dailyRateApplied', async () => {
      await assertFails(
        create({ rentalFee: 90001, totalPayable: 190001 }),
      );
      await assertFails(create({ days: 0, rentalFee: 0, totalPayable: 100000 }));
    });

    it('rejects an expiresAt that is too far, missing or not a timestamp', async () => {
      await assertFails(create({ expiresAt: hours(26) }));
      await assertFails(create({ expiresAt: undefined }));
      await assertFails(create({ expiresAt: 'tomorrow' }));
    });
  });

  describe('reviews create and delete negatives', () => {
    beforeEach(() =>
      s.seed({
        'bookings/b-done': bookingMap({ status: 'completed' }),
        'bookings/b-pend': bookingMap({ status: 'pending' }),
      }),
    );

    const rev = (overrides = {}) => ({
      bookingId: 'b-done',
      authorId: RENTER,
      subjectType: 'user',
      subjectId: OWNER,
      stars: 5,
      comment: 'Great',
      createdAt: serverTimestamp(),
      ...overrides,
    });
    const put = (uid, id, data) =>
      setDoc(doc(dbFor(uid), `reviews/${id}`), data);

    it('accepts the right id scheme on a completed booking (control)', async () => {
      await assertSucceeds(put(RENTER, 'b-done_renter4_user', rev()));
      await assertSucceeds(
        put(
          RENTER,
          'b-done_renter4_vehicle',
          rev({ subjectType: 'vehicle', subjectId: 'car-1' }),
        ),
      );
      await assertSucceeds(
        put(OWNER, 'b-done_owner1_user', rev({ authorId: OWNER, subjectId: RENTER })),
      );
    });

    it('rejects a wrong id scheme', async () => {
      await assertFails(put(RENTER, 'random-id', rev()));
      await assertFails(put(RENTER, 'b-done_renter4_vehicle', rev()));
      await assertFails(put(RENTER, 'b-done_owner1_user', rev()));
    });

    it('rejects a booking that is not completed', async () => {
      await assertFails(
        put(RENTER, 'b-pend_renter4_user', rev({ bookingId: 'b-pend' })),
      );
    });

    it('rejects stars 0, 6, 2.5 or a string', async () => {
      for (const stars of [0, 6, 2.5, '5']) {
        await assertFails(put(RENTER, 'b-done_renter4_user', rev({ stars })));
      }
    });

    it('rejects a non-party author and an unknown subjectType', async () => {
      await assertFails(
        put(OUTSIDER, 'b-done_renter5_user', rev({ authorId: OUTSIDER })),
      );
      await assertFails(
        put(RENTER, 'b-done_renter4_booking', rev({ subjectType: 'booking' })),
      );
    });

    describe('delete', () => {
      beforeEach(() =>
        s.seed({
          // renter5 reviews car-1 (owned by owner1) for another booking.
          'reviews/x_renter5_vehicle': {
            bookingId: 'x',
            authorId: OUTSIDER,
            subjectType: 'vehicle',
            subjectId: 'car-1',
            stars: 4,
          },
          'reviews/b-done_renter4_user': rev(),
        }),
      );

      it('lets the author, the reviewed user and the car owner delete', async () => {
        await assertSucceeds(deleteDoc(doc(dbFor(RENTER), 'reviews/b-done_renter4_user')));
        await assertSucceeds(deleteDoc(doc(dbFor(OUTSIDER), 'reviews/x_renter5_vehicle')));
      });

      it('lets the subject (owner of the reviewed user) delete', async () => {
        await assertSucceeds(deleteDoc(doc(dbFor(OWNER), 'reviews/b-done_renter4_user')));
        await assertSucceeds(deleteDoc(doc(dbFor(OWNER), 'reviews/x_renter5_vehicle')));
      });

      it('rejects a booking party who is neither author nor subject', async () => {
        // renter4 did not write and is not the subject of renter5's car review.
        await assertFails(deleteDoc(doc(dbFor(RENTER), 'reviews/x_renter5_vehicle')));
        // renter5 is unrelated to renter4's review of owner1.
        await assertFails(deleteDoc(doc(dbFor(OUTSIDER), 'reviews/b-done_renter4_user')));
      });

      it('rejects anonymous delete', async () => {
        await assertFails(deleteDoc(doc(s.anon(), 'reviews/b-done_renter4_user')));
      });
    });
  });

  describe('notifications create', () => {
    const note = (overrides = {}) => ({
      userId: OWNER,
      type: 'requestReceived',
      title: 'T',
      text: 'x',
      read: false,
      createdAt: serverTimestamp(),
      ...overrides,
    });

    it('accepts an unread notification for another user (control)', async () => {
      await assertSucceeds(setDoc(doc(dbFor(RENTER), 'notifications/n1'), note()));
    });

    it('rejects read: true, a missing read flag, or a non-string userId', async () => {
      await assertFails(setDoc(doc(dbFor(RENTER), 'notifications/n1'), note({ read: true })));
      const { read, ...missing } = note();
      await assertFails(setDoc(doc(dbFor(RENTER), 'notifications/n1'), missing));
      await assertFails(setDoc(doc(dbFor(RENTER), 'notifications/n1'), note({ userId: 7 })));
      await assertFails(setDoc(doc(s.anon(), 'notifications/n1'), note()));
    });
  });

  describe('ledger: at, delete, update', () => {
    beforeEach(() =>
      s.seed({
        'bookings/b-conf': bookingMap({ status: 'confirmed' }),
        'bookings/b-act': bookingMap({ status: 'active' }),
        'bookings/b-pend': bookingMap({ status: 'pending' }),
        'transactions/t1': ledgerMap('b-conf', 'charge', 'renter', 'veloce', 190000, new Date()),
      }),
    );

    it('rejects a charge whose at is a client Date', async () => {
      await s.seed({ 'bookings/b-appr': bookingMap({ status: 'approved' }) });
      const db = dbFor(RENTER);
      const batch = writeBatch(db);
      batch.update(doc(db, 'bookings/b-appr'), {
        status: 'confirmed',
        updatedAt: serverTimestamp(),
      });
      batch.set(
        doc(db, 'transactions/t-date'),
        ledgerMap('b-appr', 'charge', 'renter', 'veloce', 190000, new Date()),
      );
      await assertFails(batch.commit());
    });

    it('accepts the same charge with serverTimestamp (control)', async () => {
      await s.seed({ 'bookings/b-appr': bookingMap({ status: 'approved' }) });
      const db = dbFor(RENTER);
      const batch = writeBatch(db);
      batch.update(doc(db, 'bookings/b-appr'), {
        status: 'confirmed',
        updatedAt: serverTimestamp(),
      });
      batch.set(
        doc(db, 'transactions/t-ok'),
        ledgerMap('b-appr', 'charge', 'renter', 'veloce', 190000, serverTimestamp()),
      );
      await assertSucceeds(batch.commit());
    });

    it('rejects an outsider deleting a row and a party updating it', async () => {
      await assertFails(deleteDoc(doc(dbFor(OUTSIDER), 'transactions/t1')));
      await assertFails(updateDoc(doc(dbFor(RENTER), 'transactions/t1'), { amount: 1 }));
      await assertFails(deleteDoc(doc(s.anon(), 'transactions/t1')));
    });

    it('documents the open gap: a party can still delete its row (R2R-07)', async () => {
      // Kept on purpose, see tool/rules-test/README.md: the account eraser
      // deletes ledger rows after the bookings, in batches that cannot prove
      // the booking is gone for more than ~19 bookings.
      await assertSucceeds(deleteDoc(doc(dbFor(RENTER), 'transactions/t1')));
    });
  });

  describe('booking delete', () => {
    beforeEach(() =>
      s.seed({
        'bookings/b-done': bookingMap({ status: 'completed' }),
        'bookings/b-act': bookingMap({ status: 'active' }),
      }),
    );

    it('rejects an outsider and anonymous deleting a booking', async () => {
      await assertFails(deleteDoc(doc(dbFor(OUTSIDER), 'bookings/b-done')));
      await assertFails(deleteDoc(doc(s.anon(), 'bookings/b-done')));
    });

    it('lets a party delete a terminal booking', async () => {
      await assertSucceeds(deleteDoc(doc(dbFor(RENTER), 'bookings/b-done')));
    });

    it('documents the open gap: a party can delete an active booking (R2R-07)', async () => {
      // The eraser must delete active bookings before the user document, and
      // rules cannot tell the eraser from a manual delete. See README.
      await assertSucceeds(deleteDoc(doc(dbFor(OWNER), 'bookings/b-act')));
    });
  });
});

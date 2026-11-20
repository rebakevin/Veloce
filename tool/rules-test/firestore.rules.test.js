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
  setDoc,
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

/* eslint-disable no-console */
// Seeds the shared Veloce dev project (Firebase Admin SDK, bypasses rules).
//
//   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node seed.js
//   ... node seed.js --reset      # wipe every Veloce collection first
//   node seed.js --dry-run        # no credentials: check the data and count documents
//   node seed.js --dry-run --scenarios=phase-3   # base data + only that scenario file
//
// Per-phase dummy data lives in scenarios/phase-N.js (see scenarios/README.md).

// Field names and enum keys mirror docs/resources/TECHNICAL.md §4.2 and the
// Dart enums in lib/core/domain/enums. Keep the three in sync.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const DRY_RUN = process.argv.includes('--dry-run');

const PROJECT_ID = 'veloce-1fe08';
const PASSWORD = 'Veloce#2026'; // must equal DevAccounts.password in the app
const PLATFORM_FEE = 2000;

// Refuse ambient credentials (gcloud ADC may point at an unrelated project).
const { Timestamp } = admin.firestore;
let db = null;
if (!DRY_RUN) {
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!keyPath) {
    console.error('Set GOOGLE_APPLICATION_CREDENTIALS to the veloce-1fe08 service-account key. See tool/seed/README.md.');
    process.exit(1);
  }
  const serviceAccount = require(path.resolve(keyPath));
  if (serviceAccount.project_id !== PROJECT_ID) {
    console.error(`The key is for "${serviceAccount.project_id}", not "${PROJECT_ID}". Aborting.`);
    process.exit(1);
  }
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount), projectId: PROJECT_ID });
  db = admin.firestore();
}

const COLLECTIONS = [
  'users', 'vehicles', 'bookings', 'calendarBlocks', 'renterLocks', 'transactions',
  'cautionClaims', 'repairExpenses', 'reviews', 'notifications', 'auditLogs',
];

// ---------- time helpers ----------
const now = new Date();
const day = (offset, hour = 9) =>
  new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + offset, hour));
const ts = (date) => Timestamp.fromDate(date);
const hoursFromNow = (hours) => new Date(now.getTime() + hours * 3600 * 1000);

const photo = (seed) => `https://picsum.photos/seed/${seed}/800/600`;

// ---------- people ----------
const BASE_PEOPLE = [
  { uid: 'renter1', role: 'renter', name: 'Aline Uwase', phone: '0788100001' },
  { uid: 'renter2', role: 'renter', name: 'Eric Mugisha', phone: '0788100002' },
  { uid: 'renter3', role: 'renter', name: 'Diane Ingabire', phone: '0788100003' },
  { uid: 'renter4', role: 'renter', name: 'Samuel Nshuti', phone: '0788100004' },
  { uid: 'owner1', role: 'owner', name: 'Patrick Habimana', phone: '0788200001' },
  { uid: 'owner2', role: 'owner', name: 'Grace Mukamana', phone: '0788200002' },
  { uid: 'owner3', role: 'owner', name: 'Jean Claude Niyonzima', phone: '0788200003' },
];

// ---------- scenario files (one per phase, see scenarios/README.md) ----------
const scenarioArg = process.argv.find((arg) => arg.startsWith('--scenarios='));
const onlyScenarios = scenarioArg ? scenarioArg.split('=')[1].split(',') : null;
const scenarioDir = path.join(__dirname, 'scenarios');
const SCENARIOS = fs.existsSync(scenarioDir)
  ? fs.readdirSync(scenarioDir)
      .filter((file) => /^phase-\d+\.js$/.test(file))
      .sort()
      .filter((file) => !onlyScenarios || onlyScenarios.includes(file.replace('.js', '')))
      .map((file) => ({ file, ...require(path.join(scenarioDir, file)) }))
  : [];
const fromScenarios = (key) => SCENARIOS.flatMap((scenario) => scenario[key] ?? []);

const PEOPLE = [...BASE_PEOPLE, ...fromScenarios('people')];
const emailOf = (uid) => `${uid}@veloce.test`;

// ---------- cars ----------
const BASE_CARS = [
  ['car-1', 'owner1', 'RAB 101 A', 'Toyota', 'Vitz', 2018, 'hatchback', 'automatic', 'petrol', 5, 45000, [[3, 42000], [7, 38000]], 100000, 'Kacyiru', 'published'],
  ['car-2', 'owner1', 'RAB 202 B', 'Toyota', 'RAV4', 2020, 'suv', 'automatic', 'petrol', 5, 90000, [[3, 85000], [7, 80000]], 200000, 'Nyarutarama', 'published'],
  ['car-3', 'owner1', 'RAC 303 C', 'Suzuki', 'Swift', 2017, 'hatchback', 'manual', 'petrol', 5, 40000, [], 80000, 'Kimironko', 'published'],
  ['car-4', 'owner2', 'RAD 404 D', 'Toyota', 'Corolla', 2019, 'sedan', 'automatic', 'petrol', 5, 60000, [[4, 55000]], 150000, 'Remera', 'published'],
  ['car-5', 'owner2', 'RAE 505 E', 'Hyundai', 'Tucson', 2021, 'suv', 'automatic', 'diesel', 5, 100000, [[3, 95000]], 250000, 'Kicukiro', 'published'],
  ['car-6', 'owner2', 'RAF 606 F', 'Toyota', 'Hiace', 2016, 'minivan', 'manual', 'diesel', 14, 120000, [], 300000, 'Nyamirambo', 'published'],
  ['car-7', 'owner3', 'RAG 707 G', 'Ford', 'Ranger', 2019, 'pickup', 'manual', 'diesel', 5, 110000, [[5, 100000]], 250000, 'Gisozi', 'published'],
  ['car-8', 'owner3', 'RAH 808 H', 'Honda', 'Fit', 2015, 'hatchback', 'automatic', 'hybrid', 5, 38000, [], 80000, 'Kabeza', 'paused'],
].map(([id, ownerId, plate, make, model, year, type, transmission, fuel, seats, dailyPrice, tiers, cautionFee, neighbourhood, status]) => ({
  id, ownerId, plate, make, model, year, type, transmission, fuel, seats, dailyPrice,
  longRates: tiers.map(([fromDays, pricePerDay]) => ({ fromDays, pricePerDay })),
  cautionFee, neighbourhood, status,
}));
const CARS = [...BASE_CARS, ...fromScenarios('cars')];
const carById = Object.fromEntries(CARS.map((car) => [car.id, car]));

// ---------- pricing (mirrors PricingCalculator) ----------
function quote(car, days) {
  const tier = car.longRates.filter((t) => t.fromDays <= days).sort((a, b) => b.fromDays - a.fromDays)[0];
  const rate = tier ? tier.pricePerDay : car.dailyPrice;
  const rentalFee = days * rate;
  return { rate, rentalFee, caution: car.cautionFee, total: rentalFee + car.cautionFee };
}

// ---------- bookings: one in every status (plus an agreed-claim completion) ----------
// Renter locks (approved, confirmed, active) use three different renters; the
// pending request uses a fourth so it is not cancelled by a lock.
const BASE_BOOKINGS = [
  { key: 'pending',   status: 'pending',   car: 'car-2', renter: 'renter4', start: 5,   days: 3 },
  { key: 'approved',  status: 'approved',  car: 'car-4', renter: 'renter1', start: 4,   days: 3 },
  { key: 'declined',  status: 'declined',  car: 'car-1', renter: 'renter2', start: 10,  days: 2, reason: 'The car is not available for those days.' },
  { key: 'cancelled', status: 'cancelled', car: 'car-5', renter: 'renter3', start: 8,   days: 3, reason: 'Change of plans.', paidThenRefunded: true },
  { key: 'expired',   status: 'expired',   car: 'car-3', renter: 'renter4', start: 2,   days: 2, reason: 'The owner did not respond in time.' },
  { key: 'confirmed', status: 'confirmed', car: 'car-7', renter: 'renter2', start: 3,   days: 4 },
  { key: 'active',    status: 'active',    car: 'car-6', renter: 'renter3', start: -1,  days: 3 },
  { key: 'returning', status: 'returning', car: 'car-1', renter: 'renter1', start: -4,  days: 3 },
  { key: 'review',    status: 'review',    car: 'car-2', renter: 'renter2', start: -8,  days: 3, lateDays: 1, claim: 'disputed' },
  { key: 'completed', status: 'completed', car: 'car-4', renter: 'renter3', start: -15, days: 3, decision: 'no_issue' },
  { key: 'claimed',   status: 'completed', car: 'car-5', renter: 'renter1', start: -25, days: 4, decision: 'claim', claim: 'agreed' },
];
const BOOKINGS = [...BASE_BOOKINGS, ...fromScenarios('bookings')].map((b, index) => {
  const car = carById[b.car];
  const q = quote(car, b.days);
  return { ...b, id: `booking-${b.key}`, reference: `VLC-${1001 + index}`, ownerId: car.ownerId, carData: car, q };
});

const REACHED_PAYMENT = ['confirmed', 'active', 'returning', 'review', 'completed'];

function bookingDoc(b) {
  const start = day(b.start);
  const end = day(b.start + b.days);
  const paid = REACHED_PAYMENT.includes(b.status) || b.paidThenRefunded;
  const handedOver = ['active', 'returning', 'review', 'completed'].includes(b.status);
  const returned = ['returning', 'review', 'completed'].includes(b.status);
  const created = day(b.start - 3);
  const lateFee = b.lateDays ? Math.round(b.q.rentalFee * 1.3 ** b.lateDays - b.q.rentalFee) : 0;
  return {
    reference: b.reference,
    vehicleId: b.car,
    renterId: b.renter,
    ownerId: b.ownerId,
    startDate: ts(start),
    endDate: ts(end),
    days: b.days,
    dailyRateApplied: b.q.rate,
    rentalFee: b.q.rentalFee,
    cautionFee: b.q.caution,
    platformFee: PLATFORM_FEE,
    totalPayable: b.q.total,
    status: b.status,
    reason: b.reason ?? null,
    payDeadline: b.status === 'approved' ? ts(hoursFromNow(b.payDeadlineHours ?? 20)) : null,
    expiresAt: b.status === 'pending' ? ts(hoursFromNow(b.expiresInHours ?? 20)) : null,
    agreementAckAt: paid ? ts(day(b.start - 2)) : null,
    ownerPickupConfirmedAt: handedOver || b.pickupConfirmed === 'owner' ? ts(day(b.start, 9)) : null,
    renterPickupConfirmedAt: handedOver || b.pickupConfirmed === 'renter' ? ts(day(b.start, 10)) : null,
    returnedAt: returned ? ts(day(b.start + b.days, 17)) : null,
    ownerReturnConfirmedAt: ['review', 'completed'].includes(b.status) || b.returnConfirmed === 'owner' ? ts(day(b.start + b.days, 18)) : null,
    renterReturnConfirmedAt: ['review', 'completed'].includes(b.status) || b.returnConfirmed === 'renter' ? ts(day(b.start + b.days, 18)) : null,
    lateDays: b.lateDays ?? 0,
    lateFee,
    lateFeeWaived: false,
    cautionDecision: b.decision ?? (b.status === 'review' ? 'claim' : null),
    renterOutcomeAckAt: b.status === 'completed' ? ts(day(b.start + b.days + 1)) : null,
    completedAt: b.status === 'completed' ? ts(day(b.start + b.days + 1)) : null,
    createdAt: ts(created),
    updatedAt: ts(day(Math.min(b.start, 0))),
  };
}

// ---------- ledger (the invariant: held = charge - release - refund - claim_deduction - late_fee >= 0) ----------
function ledgerFor(b) {
  const entries = [];
  const add = (type, amount, fromParty, toParty, at) =>
    entries.push({ bookingId: b.id, vehicleId: b.car, ownerId: b.ownerId, renterId: b.renter, type, amount, fromParty, toParty,
      reference: `MOMO-${b.reference}-${type}`, status: 'success', at: ts(at) });
  const { rentalFee, caution, total } = b.q;
  if (b.paidThenRefunded) {
    add('charge', total, 'renter', 'veloce', day(b.start - 2));
    add('refund', total, 'veloce', 'renter', day(b.start - 1));
    return entries;
  }
  if (!REACHED_PAYMENT.includes(b.status)) return entries;
  add('charge', total, 'renter', 'veloce', day(b.start - 2));
  if (['confirmed'].includes(b.status)) return entries;
  add('release', rentalFee, 'veloce', 'owner', day(b.start, 10));
  add('platform_fee', PLATFORM_FEE, 'owner', 'veloce', day(b.start, 10));
  add('payout', rentalFee - PLATFORM_FEE, 'veloce', 'owner', day(b.start, 10));
  if (b.status === 'completed' && b.decision === 'no_issue') {
    add('refund', caution, 'veloce', 'renter', day(b.start + b.days + 1));
  }
  if (b.status === 'completed' && b.decision === 'claim') {
    const claimAmount = b.claimAmount ?? CLAIM_AGREED_AMOUNT;
    add('claim_deduction', claimAmount, 'veloce', 'owner', day(b.start + b.days + 1));
    add('refund', caution - claimAmount, 'veloce', 'renter', day(b.start + b.days + 1));
  }
  // Scenario-specific money movements: [type, amount, fromParty, toParty, dayOffset].
  (b.extraLedger ?? []).forEach(([type, amount, fromParty, toParty, offset]) => add(type, amount, fromParty, toParty, day(offset)));
  return entries;
}

const CLAIM_AGREED_AMOUNT = 60000;

// ---------- seeding ----------
async function wipe() {
  if (DRY_RUN) return;
  console.log('Resetting every Veloce collection...');
  for (const name of COLLECTIONS) await db.recursiveDelete(db.collection(name));
}

async function seedAccounts() {
  if (DRY_RUN) return;
  for (const person of PEOPLE) {
    const email = emailOf(person.uid);
    const fields = { email, password: PASSWORD, displayName: person.name, emailVerified: person.emailVerified !== false };
    try {
      await admin.auth().updateUser(person.uid, fields);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      await admin.auth().createUser({ uid: person.uid, ...fields });
    }
  }
}

function reviewList() {
  const completed = BOOKINGS.filter((b) => b.status === 'completed' && ['completed', 'claimed'].includes(b.key));
  const stars = { completed: [5, 5, 4], claimed: [3, 4, 5] };
  const comments = {
    completed: ['Careful driver, returned on time.', 'Smooth handover and a clean car.', 'Drives great, would rent again.'],
    claimed: ['Returned a day late with a scratch.', 'Helpful owner, clear instructions.', 'Comfortable for the whole trip.'],
  };
  return [...fromScenarios('reviews'), ...completed.flatMap((b) => [
    { id: `${b.id}_${b.ownerId}_user`, bookingId: b.id, authorId: b.ownerId, subjectType: 'user', subjectId: b.renter, stars: stars[b.key][0], comment: comments[b.key][0] },
    { id: `${b.id}_${b.renter}_user`, bookingId: b.id, authorId: b.renter, subjectType: 'user', subjectId: b.ownerId, stars: stars[b.key][1], comment: comments[b.key][1] },
    { id: `${b.id}_${b.renter}_vehicle`, bookingId: b.id, authorId: b.renter, subjectType: 'vehicle', subjectId: b.car, stars: stars[b.key][2], comment: comments[b.key][2] },
  ])];
}

function aggregate(reviews, subjectType, id) {
  const mine = reviews.filter((r) => r.subjectType === subjectType && r.subjectId === id);
  const count = mine.length;
  const avg = count ? mine.reduce((sum, r) => sum + r.stars, 0) / count : 0;
  return { ratingAvg: Math.round(avg * 10) / 10, ratingCount: count };
}

async function commitAll(operations) {
  if (DRY_RUN) {
    const perCollection = {};
    operations.forEach(([ref]) => { const root = ref.split('/')[0]; perCollection[root] = (perCollection[root] ?? 0) + 1; });
    console.log('Dry run, nothing written. Documents per collection:', perCollection);
    return;
  }
  // Firestore batches hold at most 500 writes.
  for (let i = 0; i < operations.length; i += 400) {
    const batch = db.batch();
    operations.slice(i, i + 400).forEach(([ref, data]) => batch.set(db.doc(ref), data));
    await batch.commit();
  }
}

async function seedFirestore() {
  const ops = [];
  const set = (docPath, data) => ops.push([docPath, data]);
  const reviews = reviewList();
  const completedCount = (uid) => BOOKINGS.filter((b) => b.status === 'completed' && (b.renter === uid || b.ownerId === uid)).length;

  PEOPLE.forEach((person, index) => {
    set(`users/${person.uid}`, {
      role: person.role, name: person.name, photoUrl: photo(person.uid), verified: true,
      ...aggregate(reviews, 'user', person.uid), completedCount: completedCount(person.uid), createdAt: ts(day(-60 + index)),
    });
    set(`users/${person.uid}/private/contact`, {
      email: emailOf(person.uid), phone: person.phone, dateOfBirth: ts(new Date(Date.UTC(1992, index, 10))), authProvider: 'password',
    });
    if (person.role === 'renter') {
      set(`users/${person.uid}/private/licence`, {
        number: `RW${100000 + index}`, expiry: ts(day(500)), photoUrl: photo(`licence-${person.uid}`), active: true,
      });
    } else {
      set(`users/${person.uid}/private/identity`, {
        nationalIdNumber: `11990${String(80000000000 + index * 1111).padStart(11, '0')}`, photoUrl: photo(`id-${person.uid}`),
      });
      set(`users/${person.uid}/private/payout`, { momoNumber: `78820000${index}` });
    }
  });

  CARS.forEach((car, index) => {
    const insuranceExpiry = day(car.insuranceDays ?? 200 + index);
    const medicalExpiry = day(car.medicalDays ?? 300 + index);
    set(`vehicles/${car.id}`, {
      ownerId: car.ownerId, plate: car.plate, make: car.make, model: car.model, year: car.year, type: car.type,
      transmission: car.transmission, fuel: car.fuel, seats: car.seats, features: ['Air conditioning', 'Bluetooth', 'USB charging'],
      description: `${car.make} ${car.model} in ${car.neighbourhood}, well maintained and ready to drive.`,
      dailyPrice: car.dailyPrice, longRates: car.longRates, cautionFee: car.cautionFee, neighbourhood: car.neighbourhood,
      fuelRule: 'Return with the same fuel level', smoking: 'No smoking', extras: index % 2 === 0 ? ['Child seat'] : [],
      rulesFileUrl: null, videoUrl: null, status: car.status,
      availableFrom: ts(day(car.availableFromDay ?? -5)), availableTo: ts(day(car.availableToDay ?? 120)), docsValidUntil: ts(insuranceExpiry < medicalExpiry ? insuranceExpiry : medicalExpiry),
      ...aggregate(reviews, 'vehicle', car.id), createdAt: ts(day(-50 + index)),
    });
    for (let n = 0; n < 3; n += 1) {
      set(`vehicles/${car.id}/photos/photo-${n + 1}`, {
        vehicleId: car.id, url: photo(`${car.id}-${n}`), order: n, isPrimary: n === 0,
      });
    }
    set(`vehicles/${car.id}/documents/insurance`, {
      vehicleId: car.id, number: `INS-${car.plate.replace(/ /g, '')}`, expiry: ts(insuranceExpiry), photoUrl: photo(`ins-${car.id}`), verified: true,
    });
    set(`vehicles/${car.id}/documents/medical`, {
      vehicleId: car.id, number: `MED-${car.plate.replace(/ /g, '')}`, expiry: ts(medicalExpiry), photoUrl: photo(`med-${car.id}`), verified: true,
    });
    if (car.yellowPaper ?? index % 2 === 0) {
      set(`vehicles/${car.id}/documents/yellowPaper`, {
        vehicleId: car.id, number: `YP-${car.plate.replace(/ /g, '')}`, expiry: ts(day(400)), photoUrl: photo(`yp-${car.id}`), verified: true,
      });
    }
  });

  // favourites (so the Saved tab has data)
  ['car-2', 'car-4', 'car-7'].forEach((carId) => set(`users/renter1/favourites/${carId}`, { userId: 'renter1', createdAt: ts(day(-3)) }));
  set('users/renter2/favourites/car-5', { userId: 'renter2', createdAt: ts(day(-2)) });

  BOOKINGS.forEach((b) => {
    set(`bookings/${b.id}`, bookingDoc(b));
    const renter = PEOPLE.find((p) => p.uid === b.renter);
    const owner = PEOPLE.find((p) => p.uid === b.ownerId);
    set(`bookings/${b.id}/private/renter`, { bookingId: b.id, phone: renter.phone, email: emailOf(renter.uid), meetingPoint: null });
    if (!['pending', 'declined', 'expired'].includes(b.status)) {
      set(`bookings/${b.id}/private/owner`, { bookingId: b.id, phone: owner.phone, email: emailOf(owner.uid), meetingPoint: `${b.carData.neighbourhood} roundabout` });
    }
    if (['approved', 'confirmed', 'active', 'returning', 'review'].includes(b.status)) {
      set(`calendarBlocks/${b.id}`, { vehicleId: b.car, startDate: ts(day(b.start)), endDate: ts(day(b.start + b.days)) });
    }
    if (['approved', 'confirmed', 'active'].includes(b.status)) {
      set(`renterLocks/${b.renter}`, { bookingId: b.id, createdAt: ts(day(b.start - 3)) });
    }
    ledgerFor(b).forEach((entry, i) => set(`transactions/${b.id}-${i + 1}`, entry));

    const handedOver = ['active', 'returning', 'review', 'completed'].includes(b.status);
    const returned = ['returning', 'review', 'completed'].includes(b.status);
    const items = ['exterior', 'interior', 'fuel_level', 'tyres', 'accessories'];
    [['pickup', handedOver, b.start], ['return', returned, b.start + b.days]].forEach(([kind, present, offset]) => {
      if (!present) return;
      ['owner', 'renter'].forEach((side) => {
        items.forEach((item) => set(`bookings/${b.id}/checklistEntries/${kind}_${side}_${item}`, {
          bookingId: b.id, kind, side, item, ticked: true, at: ts(day(offset, 10)),
        }));
        set(`bookings/${b.id}/checklistMedia/${kind}_${side}_1`, {
          bookingId: b.id, kind, side, mediaType: 'photo', url: photo(`${b.id}-${kind}-${side}`), at: ts(day(offset, 10)),
        });
      });
    });
  });

  // claims: one disputed (booking in review), one agreed (completed)
  const reviewBooking = BOOKINGS.find((b) => b.key === 'review');
  set(`cautionClaims/${reviewBooking.id}`, {
    originalAmount: 80000, currentAmount: 80000, reason: 'Deep scratch on the rear bumper.',
    evidenceUrls: [photo('claim-review-1'), photo('claim-review-2')], renterResponse: 'disputed',
    history: [{ amount: 80000, reason: 'Deep scratch on the rear bumper.', at: ts(day(reviewBooking.start + reviewBooking.days, 19)), response: 'disputed' }],
    status: 'open', updatedAt: ts(day(-4)),
  });
  const claimed = BOOKINGS.find((b) => b.key === 'claimed');
  set(`cautionClaims/${claimed.id}`, {
    originalAmount: CLAIM_AGREED_AMOUNT, currentAmount: CLAIM_AGREED_AMOUNT, reason: 'Cracked wing mirror.',
    evidenceUrls: [photo('claim-claimed-1')], renterResponse: 'agreed',
    history: [{ amount: CLAIM_AGREED_AMOUNT, reason: 'Cracked wing mirror.', at: ts(day(claimed.start + claimed.days, 19)), response: 'agreed' }],
    status: 'settled', updatedAt: ts(day(-20)),
  });
  // repair cost higher than the deduction -> a loss for the owner
  set('repairExpenses/repair-1', {
    bookingId: claimed.id, vehicleId: claimed.car, ownerId: claimed.ownerId, amount: 85000,
    description: 'Replaced wing mirror and repainted housing', receiptUrl: photo('receipt-1'), createdAt: ts(day(-18)),
  });

  reviews.forEach((r) => set(`reviews/${r.id}`, { ...r, createdAt: ts(day(-12)), editedAt: null }));

  const notify = (userId, type, title, text, bookingKey, read) => set(`notifications/${userId}-${type}-${bookingKey ?? 'x'}`, {
    userId, type, title, text, bookingId: bookingKey ? `booking-${bookingKey}` : null, read, createdAt: ts(day(-1)),
  });
  notify('owner1', 'request_received', 'New booking request', 'Samuel wants to rent your Toyota RAV4.', 'pending', false);
  notify('renter1', 'request_approved', 'Request approved', 'Pay within 24 hours to confirm your booking.', 'approved', false);
  notify('renter2', 'request_declined', 'Request declined', 'The car is not available for those days.', 'declined', true);
  notify('owner2', 'pickup_confirmed', 'Pickup confirmed', 'Diane confirmed pickup of your Toyota Hiace.', 'active', false);
  notify('renter2', 'claim_changed', 'Caution claim', 'The owner made a claim against your caution.', 'review', false);
  notify('renter3', 'review_due', 'Review due', 'Tell others how your rental went.', 'completed', true);

  const ctx = { set, ts, day, photo, notify, hoursFromNow, emailOf, PEOPLE, CARS, BOOKINGS, PLATFORM_FEE };
  SCENARIOS.forEach((scenario) => scenario.docs?.(ctx));

  await commitAll(ops);
  console.log(`Wrote ${ops.length} documents.`);
}

function validate() {
  const duplicates = (label, ids) => {
    const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
    if (dupes.length) throw new Error(`Duplicate ${label}: ${[...new Set(dupes)].join(', ')}`);
  };
  duplicates('person uid', PEOPLE.map((p) => p.uid));
  duplicates('car id', CARS.map((c) => c.id));
  duplicates('booking key', BOOKINGS.map((b) => b.key));
  const uids = new Set(PEOPLE.map((p) => p.uid));
  CARS.forEach((c) => { if (!uids.has(c.ownerId)) throw new Error(`Car ${c.id} has unknown owner ${c.ownerId}`); });
  BOOKINGS.forEach((b) => { if (!uids.has(b.renter)) throw new Error(`Booking ${b.key} has unknown renter ${b.renter}`); });

  const locks = {};
  const blocks = {};
  BOOKINGS.forEach((b) => {
    if (['approved', 'confirmed', 'active'].includes(b.status)) {
      if (locks[b.renter]) throw new Error(`Renter ${b.renter} holds two locks: ${locks[b.renter]} and ${b.id}`);
      locks[b.renter] = b.id;
    }
    if (['approved', 'confirmed', 'active', 'returning', 'review'].includes(b.status)) {
      (blocks[b.car] ??= []).forEach((other) => {
        if (b.start < other.start + other.days && other.start < b.start + b.days) {
          throw new Error(`Calendar blocks overlap on ${b.car}: ${other.id} and ${b.id}`);
        }
      });
      blocks[b.car].push(b);
    }
  });
  console.log(`Scenarios loaded: ${SCENARIOS.map((s) => s.file).join(', ') || 'none'}`);
  console.log(`${PEOPLE.length} people, ${CARS.length} cars, ${BOOKINGS.length} bookings.`);
}

function reconcile() {
  for (const b of BOOKINGS) {
    const held = ledgerFor(b).reduce((sum, e) => {
      if (e.type === 'charge') return sum + e.amount;
      if (['release', 'refund', 'claim_deduction', 'late_fee'].includes(e.type)) return sum - e.amount;
      return sum;
    }, 0);
    if (held < 0) throw new Error(`Held balance negative for ${b.id}: ${held}`);
    console.log(`  ${b.id.padEnd(20)} ${b.status.padEnd(10)} held RWF ${held}`);
  }
}

async function main() {
  console.log(`${DRY_RUN ? 'Dry run for' : 'Seeding'} ${PROJECT_ID}`);
  validate();
  console.log('Held balance per booking (must never be negative):');
  reconcile();
  if (process.argv.includes('--reset')) await wipe();
  await seedAccounts();
  await seedFirestore();
  console.log('Done. Sign in with any account below (password: ' + PASSWORD + ')');
  PEOPLE.forEach((p) => console.log(`  ${p.role.padEnd(6)} ${emailOf(p.uid)}  ${p.name}`));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

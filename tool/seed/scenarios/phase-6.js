// Phase 6: reviews, notifications & finances. See README.md in this folder for the contract.
//
// Everything is dated by day offsets from the seeding day. "Current month" data
// (offsets -12 .. -2) only lands in this calendar month if you seed after the ~12th;
// seed again later to refresh. Older offsets fill the earlier months of the year.
//
// Dedicated accounts (not used by other phases):
//   renter14  history of every money movement; has a booking with missing reviews
//   owner5   brand-new owner: one car, no bookings, no transactions (empty state)
//   p6-owner owner whose bookings have missing reviews (is blocked by PendingReviewChecker)
// Base accounts renter1-4 / owner1-3 get every review they owe, so they are never blocked.

// Prices of the base cars used below (mirror seed.js BASE_CARS) to compute late fees.
const BASE = {
  'car-1': { owner: 'owner1', price: 45000, tiers: [[3, 42000], [7, 38000]], caution: 100000 },
  'car-2': { owner: 'owner1', price: 90000, tiers: [[3, 85000], [7, 80000]], caution: 200000 },
  'car-3': { owner: 'owner1', price: 40000, tiers: [], caution: 80000 },
  'car-4': { owner: 'owner2', price: 60000, tiers: [[4, 55000]], caution: 150000 },
  'car-5': { owner: 'owner2', price: 100000, tiers: [[3, 95000]], caution: 250000 },
  'car-6': { owner: 'owner2', price: 120000, tiers: [], caution: 300000 },
  'car-7': { owner: 'owner3', price: 110000, tiers: [[5, 100000]], caution: 250000 },
  'p6-car-review': { owner: 'p6-owner', price: 50000, tiers: [], caution: 100000 },
};
const rentalFee = (car, days) => {
  const c = BASE[car];
  const tier = c.tiers.filter(([from]) => from <= days).sort((a, b) => b[0] - a[0])[0];
  return days * (tier ? tier[1] : c.price);
};
// Same formula as seed.js bookingDoc().
const lateFeeOf = (car, days, lateDays) => {
  const fee = rentalFee(car, days);
  return Math.round(fee * 1.3 ** lateDays - fee);
};

const RENTERS = ['renter1', 'renter2', 'renter3', 'renter4'];
let rotation = 0;
const nextRenter = () => RENTERS[rotation++ % RENTERS.length];

const bookings = [];
const repairs = []; // [id, bookingKey, amount, description, createdAtOffset]
const claims = []; // [bookingKey, amount, reason]

// done(): a completed booking. opts: renter, claim {amount, reason}, late (days), repair [amount, description, offset].
function done(key, car, start, days, opts = {}) {
  const booking = { key: `p6-${key}`, status: 'completed', car, renter: opts.renter ?? nextRenter(), start, days };
  const end = start + days;
  if (opts.claim) {
    booking.decision = 'claim';
    booking.claimAmount = opts.claim[0];
    claims.push([booking.key, opts.claim[0], opts.claim[1]]);
  } else if (opts.late) {
    // Late fee is settled out of the caution: late_fee to the owner, the rest back to the renter.
    const fee = lateFeeOf(car, days, opts.late);
    booking.lateDays = opts.late;
    booking.decision = null;
    booking.extraLedger = [
      ['late_fee', fee, 'veloce', 'owner', end + 1],
      ['refund', BASE[car].caution - fee, 'veloce', 'renter', end + 1],
    ];
  } else {
    booking.decision = 'no_issue';
  }
  if (opts.repair) repairs.push([`p6-repair-${repairs.length + 1}`, booking.key, ...opts.repair]);
  bookings.push(booking);
  return booking;
}

// ---------- owner1 (cars 1-3): this month ----------
done('o1-m1', 'car-2', -11, 3);
done('o1-m2', 'car-1', -10, 3);
done('o1-m3', 'car-3', -7, 2, { late: 1 });
done('o1-m4', 'car-1', -6, 2, { claim: [40000, 'Dent on the front door.'], repair: [70000, 'Door panel repair and repaint', -2] });
done('o1-m5', 'car-2', -4, 2);
done('o1-m6', 'car-3', -3, 1);
// ---------- owner1: earlier this year (one per month, from January) ----------
done('o1-y1', 'car-1', -300, 3);
done('o1-y2', 'car-2', -270, 4);
done('o1-y3', 'car-3', -240, 2);
done('o1-y4', 'car-1', -210, 5, { claim: [50000, 'Broken tail light.'], repair: [90000, 'Tail light and bumper repair', -205] });
done('o1-y5', 'car-2', -180, 3);
done('o1-y6', 'car-3', -150, 3, { late: 1 });
done('o1-y7', 'car-1', -120, 7);
done('o1-y8', 'car-2', -90, 2, { repair: [30000, 'Interior deep clean after a spill', -85] });
done('o1-y9', 'car-1', -60, 3);
done('o1-y10', 'car-3', -35, 2);
done('o1-y11', 'car-2', -20, 4);

// ---------- owner2 (cars 4-6): this month ----------
done('o2-m1', 'car-4', -9, 2);
done('o2-m2', 'car-5', -8, 3, { claim: [100000, 'Cracked windscreen.'], repair: [60000, 'Windscreen replacement (cheaper than the deduction)', -3] });
done('o2-m3', 'car-6', -6, 2, { late: 2 });
done('o2-m4', 'car-4', -4, 2, { repair: [120000, 'Gearbox service after the trip', -1] });
done('o2-m5', 'car-5', -3, 1);
// ---------- owner2: earlier this year ----------
done('o2-y1', 'car-4', -310, 3);
done('o2-y2', 'car-5', -280, 4);
done('o2-y3', 'car-6', -250, 2);
done('o2-y4', 'car-4', -220, 5);
done('o2-y5', 'car-5', -190, 3, { claim: [120000, 'Side panel scrape.'], repair: [200000, 'Side panel respray', -185] });
done('o2-y6', 'car-6', -160, 3);
done('o2-y7', 'car-4', -130, 4, { late: 1 });
done('o2-y8', 'car-5', -100, 2);
done('o2-y9', 'car-6', -70, 4);
done('o2-y10', 'car-4', -45, 3);
done('o2-y11', 'car-5', -30, 3);

// ---------- cancelled with refund (cancellation refund on the renter side) ----------
const cancelled = (key, car, renter, start, days) =>
  bookings.push({ key: `p6-${key}`, status: 'cancelled', car, renter, start, days, reason: 'Change of plans.', paidThenRefunded: true });
cancelled('cancel-1', 'car-2', 'renter2', -25, 3);
cancelled('cancel-2', 'car-5', 'renter3', -40, 2);

// ---------- renter14: one booking per money movement ----------
done('r9-ok', 'car-1', -100, 3, { renter: 'renter14' }); // payment + caution refund
done('r9-claim', 'car-2', -75, 3, { renter: 'renter14', claim: [70000, 'Scratched alloy wheel.'] }); // claim deduction + partial refund
done('r9-late', 'car-3', -50, 2, { renter: 'renter14', late: 1 }); // late fee + partial refund
cancelled('r9-cancel', 'car-5', 'renter14', -20, 2); // cancellation refund

// ---------- reviews: pending / partial / complete ----------
// A: nobody reviewed (owner->renter, renter->owner, renter->car all missing). Blocks renter14 and p6-owner.
bookings.push({ key: 'p6-pending-all', status: 'completed', car: 'p6-car-review', renter: 'renter14', start: -6, days: 2, decision: 'no_issue' });
// B: only the renter side is reviewed; the owner (p6-owner) still owes owner->renter.
bookings.push({ key: 'p6-pending-owner', status: 'completed', car: 'p6-car-review', renter: 'renter1', start: -12, days: 3, decision: 'no_issue' });
// C: all three reviews exist (edit test); on owner3's car so owner1/owner2 stay unaffected.
bookings.push({ key: 'p6-reviewed', status: 'completed', car: 'car-7', renter: 'renter4', start: -30, days: 3, decision: 'no_issue' });

// ---------- reviews for every completed booking except A and B's owner side ----------
const STARS = [5, 4, 5, 3, 4, 5, 2, 4, 5, 4, 3, 5];
const COMMENTS = [
  'Smooth handover and a clean car.', 'Returned on time, would rent again.', 'Great communication from start to end.',
  'Car had a small issue but the owner helped quickly.', 'Comfortable and fuel efficient.', 'Very polite and careful driver.',
  'Returned late and without notice.', 'Easy pickup near the city centre.', 'Spotless, exactly as described.',
  'Good value for the price.', 'Pickup was delayed but everything else was fine.', 'Excellent, highly recommended.',
];
const reviews = [];
let n = 0;
const pick = () => { n += 1; return [STARS[n % STARS.length], COMMENTS[n % COMMENTS.length]]; };
const reviewDay = {}; // review id -> day offset it was written
bookings.filter((b) => b.status === 'completed').forEach((b) => {
  const id = `booking-${b.key}`;
  const owner = BASE[b.car].owner;
  const date = Math.min(b.start + b.days + 2, -1);
  const add = (author, subjectType, subjectId) => {
    const [stars, comment] = pick();
    const reviewId = `${id}_${author}_${subjectType}`;
    reviews.push({ id: reviewId, bookingId: id, authorId: author, subjectType, subjectId, stars, comment });
    reviewDay[reviewId] = date;
  };
  if (b.key === 'p6-pending-all') return;
  add(b.renter, 'user', owner);
  add(b.renter, 'vehicle', b.car);
  if (b.key !== 'p6-pending-owner') add(owner, 'user', b.renter);
});

// ---------- notifications ----------
const TYPES = [
  ['request_received', 'New booking request', 'A renter wants to rent your car.'],
  ['request_approved', 'Request approved', 'Pay within 24 hours to confirm your booking.'],
  ['request_declined', 'Request declined', 'The car is not available for those days.'],
  ['request_expired', 'Request expired', 'The owner did not respond in time.'],
  ['booking_cancelled', 'Booking cancelled', 'The booking was cancelled and refunded.'],
  ['payment_received', 'Payment received', 'The payment for your booking was received.'],
  ['payment_deadline', 'Payment deadline', 'Your payment is due in a few hours.'],
  ['pickup_confirmed', 'Pickup confirmed', 'The other side confirmed the pickup.'],
  ['return_confirmed', 'Return confirmed', 'The other side confirmed the return.'],
  ['claim_changed', 'Claim updated', 'The caution claim was changed.'],
  ['late_fee_applied', 'Late fee applied', 'A late fee was applied to the booking.'],
  ['review_due', 'Review due', 'Tell others how your rental went.'],
];
// [type index, bookingKey|null, hours ago, read]; the first 12 cover every type, the next 6 are repeats.
function notificationPlan(links) {
  const hours = [2, 5, 9, 20, 30, 50, 80, 120, 200, 330, 500, 800, 3, 26, 75, 150, 400, 1200];
  const read = [false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, true];
  const typeIdx = [...Array(12).keys(), 0, 7, 9, 11, 5, 3];
  return typeIdx.map((t, i) => [t, links[i % links.length], hours[i], read[i]]);
}

module.exports = {
  people: [
    { uid: 'renter14', role: 'renter', name: 'Chantal Uwimana', phone: '0788100014' },
    { uid: 'owner5', role: 'owner', name: 'Olivier Kamanzi', phone: '0788200005' },
    { uid: 'p6-owner', role: 'owner', name: 'Frank Ndayisaba', phone: '0788200090' },
  ],
  cars: [
    { id: 'p6-car-new', ownerId: 'owner5', plate: 'RAN 505 N', make: 'Mazda', model: 'Demio', year: 2016, type: 'hatchback',
      transmission: 'automatic', fuel: 'petrol', seats: 5, dailyPrice: 42000, longRates: [], cautionFee: 90000,
      neighbourhood: 'Kicukiro', status: 'published' },
    { id: 'p6-car-review', ownerId: 'p6-owner', plate: 'RAP 616 P', make: 'Nissan', model: 'Note', year: 2017, type: 'hatchback',
      transmission: 'automatic', fuel: 'petrol', seats: 5, dailyPrice: 50000, longRates: [], cautionFee: 100000,
      neighbourhood: 'Kibagabaga', status: 'published' },
  ],
  bookings,
  reviews,

  docs(ctx) {
    const { set, ts, day, photo, hoursFromNow } = ctx;

    // Reviews are written with their own dates (seed.js stamps all of them with day -12).
    reviews.forEach((r) => {
      const edited = r.id === 'booking-p6-reviewed_renter4_vehicle';
      set(`reviews/${r.id}`, {
        ...r, createdAt: ts(day(reviewDay[r.id], 12)), editedAt: edited ? ts(day(-20, 12)) : null,
      });
    });

    // Claims behind the claim_deduction ledger rows.
    claims.forEach(([bookingKey, amount, reason]) => {
      const b = bookings.find((x) => x.key === bookingKey);
      const at = ts(day(b.start + b.days, 19));
      set(`cautionClaims/booking-${bookingKey}`, {
        originalAmount: amount, currentAmount: amount, reason, evidenceUrls: [photo(`${bookingKey}-claim`)],
        renterResponse: 'agreed', history: [{ amount, reason, at, response: 'agreed' }],
        status: 'settled', updatedAt: ts(day(b.start + b.days + 1)),
      });
    });

    // Repair costs: some larger than the deduction (loss), one smaller (no loss), some without a claim.
    repairs.forEach(([id, bookingKey, amount, description, offset]) => {
      const b = bookings.find((x) => x.key === bookingKey);
      set(`repairExpenses/${id}`, {
        bookingId: `booking-${bookingKey}`, vehicleId: b.car, ownerId: BASE[b.car].owner, amount, description,
        receiptUrl: photo(`${id}-receipt`), createdAt: ts(day(offset)),
      });
    });

    // Notifications: 18 each (every type once + repeats), 12 unread so the badge shows.
    const write = (userId, links) => notificationPlan(links).forEach(([t, bookingKey, hoursAgo, read], i) => {
      const [type, title, text] = TYPES[t];
      set(`notifications/p6-${userId}-${String(i + 1).padStart(2, '0')}`, {
        userId, type, title, text, bookingId: bookingKey ? `booking-${bookingKey}` : null, read,
        createdAt: ts(hoursFromNow(-hoursAgo)),
      });
    });
    write('owner1', ['p6-o1-m4', 'p6-o1-m6', 'p6-o1-m3', 'p6-o1-m5', 'p6-o1-m2', 'p6-r9-late', 'p6-o1-y11']);
    write('renter14', ['p6-r9-late', 'p6-r9-claim', 'p6-r9-ok', 'p6-pending-all', 'p6-r9-cancel']);
  },
};

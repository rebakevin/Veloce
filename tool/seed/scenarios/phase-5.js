// Phase 5: handover, return and caution settlement.
//
// Base data already covers: booking-confirmed (renter2, nobody confirmed pickup),
// booking-active (renter3, not late), booking-returning, booking-review (disputed
// claim) and the completed ones. This file adds the edge cases around them.
//
// Reserved renters: renter12 (confirmed lock) and renter13 (active lock); renter5-renter11 belong to phases 3 and 4. Each renter
// holds at most one lock, so the rest of the bookings below are returning, review or
// completed (no lock) and reuse renter12.

const ITEMS = ['exterior', 'interior', 'fuel_level', 'tyres', 'accessories'];

module.exports = {
  people: [
    { uid: 'renter12', role: 'renter', name: 'Emmanuel Kayitare', phone: '0788100012' },
    { uid: 'renter13', role: 'renter', name: 'Jeanne Uwamahoro', phone: '0788100013' },
  ],

  bookings: [
    // Confirmed, only the OWNER has confirmed pickup: the renter sees "confirm", the
    // owner sees "waiting for the other side". The renter's confirmation is the second one.
    { key: 'p5-pickup-one-side', status: 'confirmed', car: 'car-5', renter: 'renter12', start: 1, days: 3, pickupConfirmed: 'owner' },
    // Active and already past its end date (about 1-2 days late, depending on the hour):
    // late fee preview on return. 120,000 rental, 80,000 caution: from 2 days the fee is capped.
    { key: 'p5-active-late', status: 'active', car: 'car-3', renter: 'renter13', start: -4, days: 3 },
    // Returning, only the renter has confirmed the return.
    { key: 'p5-return-one-side', status: 'returning', car: 'car-7', renter: 'renter12', start: -6, days: 3, returnConfirmed: 'renter' },
    // Returning, both confirmed the return (see docs), owner has not decided yet.
    { key: 'p5-return-undecided', status: 'returning', car: 'car-4', renter: 'renter12', start: -5, days: 2 },
    // Review, claim just made, the renter has not responded yet.
    { key: 'p5-claim-open', status: 'review', car: 'car-1', renter: 'renter12', start: -12, days: 3 },
    // Review, renter disputed 120,000, owner re-claimed 70,000 (history of two entries).
    { key: 'p5-claim-reclaim', status: 'review', car: 'car-2', renter: 'renter12', start: -17, days: 3 },
    // Review with a late fee already charged (1 day late = 54,000) plus an open claim of 80,000.
    { key: 'p5-late-charged', status: 'review', car: 'car-4', renter: 'renter12', start: -12, days: 3, lateDays: 1,
      extraLedger: [['late_fee', 54000, 'veloce', 'owner', -9]] },
    // Completed, 2 days late but the owner waived the late fee (see docs).
    { key: 'p5-late-waived', status: 'completed', car: 'car-3', renter: 'renter12', start: -22, days: 2, lateDays: 2, decision: 'no_issue' },
    // Completed, no repair expense logged yet.
    { key: 'p5-repair-none', status: 'completed', car: 'car-3', renter: 'renter12', start: -28, days: 2, decision: 'no_issue' },
    // Completed with an agreed claim of 50,000 and two repair expenses (105,000 in total).
    { key: 'p5-repair-two', status: 'completed', car: 'car-5', renter: 'renter12', start: -35, days: 3, decision: 'claim', claimAmount: 50000 },
  ],

  docs(ctx) {
    const { set, ts, day, photo, notify } = ctx;
    const booking = (key) => ctx.BOOKINGS.find((b) => b.key === key);

    // ---- full booking doc rebuild, only for fields the generator cannot express ----
    // Mirrors bookingDoc() in seed.js; used for our own ids only.
    const rebuild = (key, patch) => {
      const b = booking(key);
      const handedOver = ['active', 'returning', 'review', 'completed'].includes(b.status);
      const returned = ['returning', 'review', 'completed'].includes(b.status);
      const lateFee = b.lateDays ? Math.round(b.q.rentalFee * 1.3 ** b.lateDays - b.q.rentalFee) : 0;
      set(`bookings/${b.id}`, {
        reference: b.reference, vehicleId: b.car, renterId: b.renter, ownerId: b.ownerId,
        startDate: ts(day(b.start)), endDate: ts(day(b.start + b.days)), days: b.days,
        dailyRateApplied: b.q.rate, rentalFee: b.q.rentalFee, cautionFee: b.q.caution,
        platformFee: ctx.PLATFORM_FEE, totalPayable: b.q.total, status: b.status, reason: null,
        payDeadline: null, expiresAt: null, agreementAckAt: ts(day(b.start - 2)),
        ownerPickupConfirmedAt: handedOver ? ts(day(b.start, 9)) : null,
        renterPickupConfirmedAt: handedOver ? ts(day(b.start, 10)) : null,
        returnedAt: returned ? ts(day(b.start + b.days, 17)) : null,
        ownerReturnConfirmedAt: null, renterReturnConfirmedAt: null,
        lateDays: b.lateDays ?? 0, lateFee, lateFeeWaived: false,
        cautionDecision: b.decision ?? (b.status === 'review' ? 'claim' : null),
        renterOutcomeAckAt: b.status === 'completed' ? ts(day(b.start + b.days + 1)) : null,
        completedAt: b.status === 'completed' ? ts(day(b.start + b.days + 1)) : null,
        createdAt: ts(day(b.start - 3)), updatedAt: ts(day(Math.min(b.start, 0))),
        ...patch,
      });
    };

    // Both sides confirmed the return, caution decision still open (no_issue vs claim).
    const returnDay = (key) => booking(key).start + booking(key).days;
    rebuild('p5-return-undecided', {
      ownerReturnConfirmedAt: ts(day(returnDay('p5-return-undecided'), 18)),
      renterReturnConfirmedAt: ts(day(returnDay('p5-return-undecided'), 18)),
    });
    // Owner waived the late fee: the amount stays on the booking, lateFeeWaived is true,
    // and there is no late_fee ledger row.
    rebuild('p5-late-waived', {
      ownerReturnConfirmedAt: ts(day(returnDay('p5-late-waived'), 18)),
      renterReturnConfirmedAt: ts(day(returnDay('p5-late-waived'), 18)),
      lateFeeWaived: true,
    });

    // ---- partial checklists (the confirm button must stay disabled until a photo exists) ----
    const entries = (key, kind, side, tickedCount, offset) => {
      const b = booking(key);
      ITEMS.forEach((item, i) => set(`bookings/${b.id}/checklistEntries/${kind}_${side}_${item}`, {
        bookingId: b.id, kind, side, item, ticked: i < tickedCount, at: ts(day(offset, 10)),
      }));
    };
    const media = (key, kind, side, offset) => {
      const b = booking(key);
      set(`bookings/${b.id}/checklistMedia/${kind}_${side}_1`, {
        bookingId: b.id, kind, side, mediaType: 'photo', url: photo(`${b.id}-${kind}-${side}`), at: ts(day(offset, 10)),
      });
    };
    // Pickup: owner finished (5 items + photo), renter has 3 of 5 ticked and no photo.
    const pickup = booking('p5-pickup-one-side');
    entries('p5-pickup-one-side', 'pickup', 'owner', 5, pickup.start);
    media('p5-pickup-one-side', 'pickup', 'owner', pickup.start);
    entries('p5-pickup-one-side', 'pickup', 'renter', 3, pickup.start);
    // Active and late: the return checklist is started, 3 of 5 ticked, no photo on either side.
    const late = booking('p5-active-late');
    entries('p5-active-late', 'return', 'renter', 3, late.start + late.days);
    entries('p5-active-late', 'return', 'owner', 3, late.start + late.days);
    // Returning, one side only: owner's return checklist is only half done, no photo.
    const ret = booking('p5-return-one-side');
    entries('p5-return-one-side', 'return', 'owner', 2, ret.start + ret.days);

    // ---- caution claims (docId = booking id; renterResponse 'none' = no response yet) ----
    const claimAt = (key, hour) => ts(day(returnDay(key), hour));
    const open = booking('p5-claim-open');
    set(`cautionClaims/${open.id}`, {
      originalAmount: 60000, currentAmount: 60000, reason: 'Dent on the driver door and a broken mirror cover.',
      evidenceUrls: [photo('p5-claim-open-1'), photo('p5-claim-open-2')], renterResponse: 'none',
      history: [{ amount: 60000, reason: 'Dent on the driver door and a broken mirror cover.', at: claimAt('p5-claim-open', 19), response: 'none' }],
      status: 'open', updatedAt: ts(day(-8)),
    });

    const reclaim = booking('p5-claim-reclaim');
    set(`cautionClaims/${reclaim.id}`, {
      originalAmount: 120000, currentAmount: 70000, reason: 'Scratches on the left side, paint repair quoted at 70,000.',
      evidenceUrls: [photo('p5-claim-reclaim-1'), photo('p5-claim-reclaim-2'), photo('p5-claim-reclaim-3')], renterResponse: 'none',
      history: [
        { amount: 120000, reason: 'Heavy scratches and a cracked bumper.', at: claimAt('p5-claim-reclaim', 19), response: 'disputed' },
        { amount: 70000, reason: 'Scratches on the left side, paint repair quoted at 70,000.', at: ts(day(-12, 11)), response: 'none' },
      ],
      status: 'open', updatedAt: ts(day(-12, 11)),
    });

    const charged = booking('p5-late-charged');
    set(`cautionClaims/${charged.id}`, {
      originalAmount: 80000, currentAmount: 80000, reason: 'Seat upholstery torn on the back seat.',
      evidenceUrls: [photo('p5-late-charged-1')], renterResponse: 'none',
      history: [{ amount: 80000, reason: 'Seat upholstery torn on the back seat.', at: claimAt('p5-late-charged', 19), response: 'none' }],
      status: 'open', updatedAt: ts(day(-8)),
    });

    const repair = booking('p5-repair-two');
    set(`cautionClaims/${repair.id}`, {
      originalAmount: 50000, currentAmount: 50000, reason: 'Broken tail light.',
      evidenceUrls: [photo('p5-repair-two-claim')], renterResponse: 'agreed',
      history: [{ amount: 50000, reason: 'Broken tail light.', at: claimAt('p5-repair-two', 19), response: 'agreed' }],
      status: 'settled', updatedAt: ts(day(-31)),
    });

    // ---- repair expenses: two on p5-repair-two (105,000 > the 50,000 deduction), none on p5-repair-none ----
    [['p5-repair-1', 40000, 'Replaced tail light unit', -33], ['p5-repair-2', 65000, 'Body shop: bumper repaint and fitting', -32]]
      .forEach(([id, amount, description, offset]) => set(`repairExpenses/${id}`, {
        bookingId: repair.id, vehicleId: repair.car, ownerId: repair.ownerId, amount, description,
        receiptUrl: photo(`${id}-receipt`), createdAt: ts(day(offset)),
      }));

    // ---- notifications ----
    notify('renter12', 'pickup_confirmed', 'Pickup confirmed', 'Grace confirmed pickup of your Hyundai Tucson. Confirm yours to start the rental.', 'p5-pickup-one-side', false);
    notify('renter12', 'claim_changed', 'Caution claim', 'The owner made a claim of RWF 60,000 against your caution.', 'p5-claim-open', false);
    notify('renter12', 'claim_changed', 'Caution claim updated', 'The owner lowered the claim to RWF 70,000.', 'p5-claim-reclaim', false);
  },
};

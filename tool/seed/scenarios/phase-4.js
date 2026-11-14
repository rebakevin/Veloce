// Phase 4 (booking decision & payment): extra requests, approvals and bookings.
// Reserved uids: renter6 ... renter11. Day offsets are relative to today.
// One lock per renter and no overlapping calendar blocks per car (the seed checks both).

// Hours until tomorrow 09:00 UTC (the seeded pickup time), capped at 24:
// the payment deadline is the earlier of +24 h and the pickup date.
const now = new Date();
const pickupTomorrow = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1, 9);
const hoursToPickup = Math.min(24, (pickupTomorrow - now.getTime()) / 3600000);

const renter = (uid, name, phone) => ({ uid, role: 'renter', name, phone });

module.exports = {
  people: [
    renter('renter6', 'Claudine Uwimana', '0788100006'),
    renter('renter7', 'Olivier Habineza', '0788100007'),
    renter('renter8', 'Beata Mukeshimana', '0788100008'),
    renter('renter9', 'Innocent Ndayisaba', '0788100009'),
    renter('renter10', 'Josiane Uwera', '0788100010'),
    renter('renter11', 'Thierry Bizimana', '0788100011'),
  ],

  bookings: [
    // --- Approve: overlapping pending requests (base: renter4 on car-2, days +5..+8) ---
    // Overlaps the base request; approving either one declines the other.
    { key: 'p4-pending-overlap', status: 'pending', car: 'car-2', renter: 'renter6', start: 6, days: 2 },
    // Does NOT overlap: must stay pending after the base request is approved.
    { key: 'p4-pending-no-overlap', status: 'pending', car: 'car-2', renter: 'renter4', start: 20, days: 2 },

    // --- Approve fails: renter7 already holds a lock (p4-approved-pay) and also has this pending request ---
    // effectiveStatus of this one is cancelled.
    { key: 'p4-pending-locked-renter', status: 'pending', car: 'car-1', renter: 'renter7', start: 20, days: 2 },
    // The lock itself: an approved booking to pay (deadline in about 20 h).
    { key: 'p4-approved-pay', status: 'approved', car: 'car-3', renter: 'renter7', start: 15, days: 2 },

    // --- Lazy expiry ---
    // Pending, 24 h window already passed 3 h ago.
    { key: 'p4-pending-expired', status: 'pending', car: 'car-5', renter: 'renter4', start: 10, days: 2, expiresInHours: -3 },
    // Approved, payment deadline already passed 2 h ago.
    { key: 'p4-approved-pastdue', status: 'approved', car: 'car-6', renter: 'renter8', start: 10, days: 2, payDeadlineHours: -2 },
    // Approved, deadline in about 1 hour (countdown).
    { key: 'p4-approved-1h', status: 'approved', car: 'car-4', renter: 'renter9', start: 12, days: 2, payDeadlineHours: 1 },
    // Approved, pickup tomorrow: deadline = earlier of +24 h and the pickup (here: pickup).
    { key: 'p4-approved-pickup-soon', status: 'approved', car: 'car-3', renter: 'renter10', start: 1, days: 2, payDeadlineHours: hoursToPickup },

    // --- Cancel with full refund (paid, confirmed, pickup not yet confirmed) ---
    { key: 'p4-confirmed-cancel', status: 'confirmed', car: 'car-7', renter: 'renter11', start: 20, days: 3 },

    // --- My Activity grouped by car: more open requests for each owner ---
    { key: 'p4-pending-car3', status: 'pending', car: 'car-3', renter: 'renter6', start: 25, days: 2 },
    { key: 'p4-pending-car1-b', status: 'pending', car: 'car-1', renter: 'renter4', start: 25, days: 3 },
    { key: 'p4-pending-car4', status: 'pending', car: 'car-4', renter: 'renter6', start: 30, days: 2 },
    { key: 'p4-pending-car6', status: 'pending', car: 'car-6', renter: 'renter4', start: 22, days: 2 },
    { key: 'p4-pending-car7', status: 'pending', car: 'car-7', renter: 'renter6', start: 30, days: 2 },

    // --- Past tab: declined, cancelled, expired ---
    { key: 'p4-declined', status: 'declined', car: 'car-2', renter: 'renter6', start: 14, days: 2, reason: 'The car is booked for a family event.' },
    { key: 'p4-cancelled-unpaid', status: 'cancelled', car: 'car-6', renter: 'renter4', start: 14, days: 2, reason: 'Found another car.' },
    { key: 'p4-cancelled-refunded', status: 'cancelled', car: 'car-7', renter: 'renter4', start: 12, days: 2, reason: 'Trip postponed.', paidThenRefunded: true },
    { key: 'p4-expired-payment', status: 'expired', car: 'car-5', renter: 'renter6', start: 15, days: 2, reason: 'Payment was not made in time.' },
  ],
};

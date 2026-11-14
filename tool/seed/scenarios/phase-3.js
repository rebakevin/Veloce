// Phase 3 (renter discovery & request): extra cars, one unverified renter, calendar
// blocks and favourites so search, filters, availability and request rules are testable.
// Base cars car-1..car-8 are published except car-8 (paused). Owners are owner1-3 only.

const car = (id, ownerId, plate, make, model, year, type, transmission, fuel, seats, dailyPrice, tiers, cautionFee, neighbourhood, extra = {}) => ({
  id: `p3-car-${id}`, ownerId, plate, make, model, year, type, transmission, fuel, seats, dailyPrice,
  longRates: tiers.map(([fromDays, pricePerDay]) => ({ fromDays, pricePerDay })),
  cautionFee, neighbourhood, status: 'published', ...extra,
});

module.exports = {
  people: [
    // Email NOT verified: the "email not verified" request failure.
    { uid: 'renter5', role: 'renter', name: 'Clarisse Mukeshimana', phone: '0788100005', emailVerified: false },
  ],

  cars: [
    // Same neighbourhood as car-1 (Kacyiru): three cars in one area.
    car('kacyiru-2', 'owner2', 'RAM 901 M', 'Mazda', 'Demio', 2018, 'hatchback', 'automatic', 'petrol', 5, 48000, [[3, 45000]], 100000, 'Kacyiru'),
    car('kacyiru-3', 'owner3', 'RAM 902 M', 'Nissan', 'Almera', 2016, 'sedan', 'manual', 'petrol', 5, 35000, [[3, 32000]], 70000, 'Kacyiru'),
    // Same neighbourhood as car-2 (Nyarutarama), the most expensive car with two tiers.
    car('nyarutarama-2', 'owner3', 'RAM 903 M', 'Toyota', 'Land Cruiser', 2022, 'suv', 'automatic', 'diesel', 7, 250000, [[3, 230000], [7, 210000]], 500000, 'Nyarutarama'),
    // Cheapest car, 4 seats.
    car('kimironko-2', 'owner1', 'RAM 904 M', 'Daihatsu', 'Mira', 2014, 'hatchback', 'manual', 'petrol', 4, 25000, [], 50000, 'Kimironko'),
    // New neighbourhoods, 7 seats and electric.
    car('minivan-7', 'owner2', 'RAM 905 M', 'Toyota', 'Noah', 2017, 'minivan', 'automatic', 'hybrid', 7, 85000, [[3, 80000]], 180000, 'Kibagabaga'),
    car('electric', 'owner1', 'RAM 906 M', 'Nissan', 'Leaf', 2020, 'hatchback', 'automatic', 'electric', 5, 70000, [], 150000, 'Kimihurura'),
    // Short availability window: only free from day 5 to day 9.
    car('short-window', 'owner3', 'RAM 907 M', 'Suzuki', 'Dzire', 2019, 'sedan', 'automatic', 'petrol', 5, 52000, [], 100000, 'Kibagabaga',
      { availableFromDay: 5, availableToDay: 9 }),
    // Calendar blocks in the middle of its window (see docs below).
    car('block-mid', 'owner2', 'RAM 908 M', 'Toyota', 'Premio', 2018, 'sedan', 'automatic', 'petrol', 5, 65000, [[3, 60000]], 130000, 'Remera'),
    // Published but insurance expired 3 days ago: must NOT appear in search (docsValidUntil < today).
    car('docs-expired', 'owner3', 'RAM 909 M', 'Isuzu', 'D-Max', 2017, 'pickup', 'manual', 'diesel', 5, 95000, [], 200000, 'Gisozi',
      { insuranceDays: -3 }),
  ],

  // No extra bookings: statuses that block a car (approved, confirmed, active) also lock a
  // renter, and renter1-4 already hold or need their lock. Blocks are written in docs().
  bookings: [],

  docs(ctx) {
    // Blocks without a booking behind them, in the middle of the p3-car-block-mid window.
    ctx.set('calendarBlocks/p3-block-mid-1', { vehicleId: 'p3-car-block-mid', startDate: ctx.ts(ctx.day(20)), endDate: ctx.ts(ctx.day(23)) });
    ctx.set('calendarBlocks/p3-block-mid-2', { vehicleId: 'p3-car-block-mid', startDate: ctx.ts(ctx.day(30)), endDate: ctx.ts(ctx.day(32)) });
    // A block on a car that otherwise has a long free window.
    ctx.set('calendarBlocks/p3-block-electric', { vehicleId: 'p3-car-electric', startDate: ctx.ts(ctx.day(12)), endDate: ctx.ts(ctx.day(15)) });

    // renter1 already has car-2, car-4, car-7: add four more (7 hearts, Saved count and list).
    ['p3-car-kacyiru-2', 'p3-car-nyarutarama-2', 'p3-car-electric', 'p3-car-minivan-7'].forEach((carId, i) =>
      ctx.set(`users/renter1/favourites/${carId}`, { userId: 'renter1', createdAt: ctx.ts(ctx.day(-2 - i)) }));
    // renter3 saved a paused car: how does the Saved tab show an unavailable car?
    ctx.set('users/renter3/favourites/car-8', { userId: 'renter3', createdAt: ctx.ts(ctx.day(-1)) });
    // renter4 and renter5 have no favourites (empty Saved tab).
  },
};

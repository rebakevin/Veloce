// Phase 2 (Owner: cars & availability) dummy data. See scenarios/README.md.
//
// - owner4: brand-new owner with zero cars (empty "My cars" state, first listing).
// - owner1 gets four extra cars on top of car-1..3, so one account covers most checks.
// - Base cars with open bookings are reused for "remove blocked": car-2 (pending),
//   car-1 (returning), car-4 (approved), car-7 (confirmed), car-6 (active).
module.exports = {
  people: [
    { uid: 'owner4', role: 'owner', name: 'Claudine Uwimana', phone: '0788200004' },
    // Holds the lock of the future confirmed booking below (locked days on the Availability screen).
    { uid: 'renter15', role: 'renter', name: 'Olivier Habineza', phone: '0788100015' },
  ],
  cars: [
    // Paused because the insurance expired 10 days ago (banner + replace-document flow).
    { id: 'p2-car-expired', ownerId: 'owner1', plate: 'RAJ 909 J', make: 'Nissan', model: 'Note', year: 2016,
      type: 'hatchback', transmission: 'automatic', fuel: 'petrol', seats: 5, dailyPrice: 35000, longRates: [],
      cautionFee: 70000, neighbourhood: 'Kanombe', status: 'paused',
      insuranceDays: -10, medicalDays: 200, yellowPaper: true, availableFromDay: -5, availableToDay: 120 },
    // Insurance + medical only, published: add the yellow paper later.
    { id: 'p2-car-noyellow', ownerId: 'owner1', plate: 'RAK 111 K', make: 'Mazda', model: 'Demio', year: 2018,
      type: 'hatchback', transmission: 'automatic', fuel: 'petrol', seats: 5, dailyPrice: 42000, longRates: [],
      cautionFee: 90000, neighbourhood: 'Gikondo', status: 'published',
      insuranceDays: 180, medicalDays: 150, yellowPaper: false, availableFromDay: -5, availableToDay: 120 },
    // Three long-rental tiers (the maximum), strictly decreasing prices.
    { id: 'p2-car-tiers', ownerId: 'owner1', plate: 'RAL 222 L', make: 'Toyota', model: 'Land Cruiser Prado', year: 2019,
      type: 'suv', transmission: 'automatic', fuel: 'diesel', seats: 7, dailyPrice: 150000,
      longRates: [{ fromDays: 3, pricePerDay: 140000 }, { fromDays: 7, pricePerDay: 125000 }, { fromDays: 14, pricePerDay: 110000 }],
      cautionFee: 300000, neighbourhood: 'Nyarutarama', status: 'published',
      insuranceDays: 250, medicalDays: 220, yellowPaper: true, availableFromDay: -5, availableToDay: 150 },
    // Published with a short availability window (today-2 .. today+14) and an open booking
    // (returning, calendar block from -3 to today): remove is blocked and booked days are locked.
    { id: 'p2-car-window', ownerId: 'owner1', plate: 'RAM 333 M', make: 'Kia', model: 'Picanto', year: 2020,
      type: 'hatchback', transmission: 'manual', fuel: 'petrol', seats: 4, dailyPrice: 30000, longRates: [],
      cautionFee: 60000, neighbourhood: 'Kimihurura', status: 'published',
      insuranceDays: 160, medicalDays: 140, yellowPaper: true, availableFromDay: -2, availableToDay: 14 },
  ],
  bookings: [
    { key: 'p2-window-returning', status: 'returning', car: 'p2-car-window', renter: 'renter4', start: -3, days: 3 },
    { key: 'p2-tiers-confirmed', status: 'confirmed', car: 'p2-car-tiers', renter: 'renter15', start: 10, days: 4 },
  ],
};

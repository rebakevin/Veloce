/// Who performs a booking transition.
enum BookingActor {
  renter('renter', 'Renter'),
  owner('owner', 'Car owner');

  const BookingActor(this.key, this.label);

  final String key;
  final String label;
}

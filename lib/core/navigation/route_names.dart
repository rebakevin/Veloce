/// Every path in the app (TECHNICAL.md §10). Feature routes and `context.go`
/// calls use these; no path literals elsewhere.
abstract final class RouteNames {
  // Auth (Phase 1)
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String registerRole = '/register/role';
  static const String registerDetails = '/register/details';
  static const String registerVerify = '/register/verify';
  static const String registerWelcome = '/register/welcome';
  static const String verifyEmail = '/verify-email';
  static const String devLogin = '/dev-login';

  // Renter tabs and discovery (Phase 3)
  static const String renterHome = '/renter/home';
  static const String renterSearch = '/renter/search';
  static const String renterFilters = '/renter/filters';
  static const String renterResults = '/renter/results';
  static const String carPattern = '/car/:id';
  static String car(String id) => '/car/$id';
  static const String carMediaPattern = '/car/:id/media';
  static String carMedia(String id) => '/car/$id/media';
  static const String carBookPattern = '/car/:id/book';
  static String carBook(String id) => '/car/$id/book';
  static const String bookingRequestedPattern = '/booking/:id/requested';
  static String bookingRequested(String id) => '/booking/$id/requested';

  // Activity and booking (Phase 4)
  static const String renterActivity = '/renter/activity';
  static const String ownerActivity = '/owner/activity';
  static const String bookingPattern = '/booking/:id';
  static String booking(String id) => '/booking/$id';
  static const String bookingDecisionPattern = '/booking/:id/decision';
  static String bookingDecision(String id) => '/booking/$id/decision';
  static const String bookingPayPattern = '/booking/:id/pay';
  static String bookingPay(String id) => '/booking/$id/pay';
  static const String bookingPayResultPattern = '/booking/:id/pay/result';
  static String bookingPayResult(String id) => '/booking/$id/pay/result';
  static const String bookingAgreementPattern = '/booking/:id/agreement';
  static String bookingAgreement(String id) => '/booking/$id/agreement';

  // Handover (Phase 5)
  static const String bookingPickupPattern = '/booking/:id/pickup';
  static String bookingPickup(String id) => '/booking/$id/pickup';
  static const String bookingReturnPattern = '/booking/:id/return';
  static String bookingReturn(String id) => '/booking/$id/return';
  static const String bookingSettlePattern = '/booking/:id/settle';
  static String bookingSettle(String id) => '/booking/$id/settle';
  static const String bookingClaimPattern = '/booking/:id/claim';
  static String bookingClaim(String id) => '/booking/$id/claim';
  static const String bookingRepairCostPattern = '/booking/:id/repair-cost';
  static String bookingRepairCost(String id) => '/booking/$id/repair-cost';

  // Owner (Phases 2 and 6)
  static const String ownerHome = '/owner/home';
  static const String ownerCars = '/owner/cars';
  static const String ownerCarNew = '/owner/cars/new';
  static const String ownerCarEditPattern = '/owner/cars/:id/edit';
  static String ownerCarEdit(String id) => '/owner/cars/$id/edit';
  static const String ownerCarAvailabilityPattern =
      '/owner/cars/:id/availability';
  static String ownerCarAvailability(String id) =>
      '/owner/cars/$id/availability';
  static const String ownerCarDocumentsPattern = '/owner/cars/:id/documents';
  static String ownerCarDocuments(String id) => '/owner/cars/$id/documents';
  static const String ownerFinances = '/owner/finances';
  static const String ownerTransactions = '/owner/finances/transactions';
  static const String ownerCarFinancesPattern = '/owner/finances/car/:carId';
  static String ownerCarFinances(String carId) => '/owner/finances/car/$carId';
  static const String ownerCarTransactionsPattern =
      '/owner/finances/car/:carId/transactions';
  static String ownerCarTransactions(String carId) =>
      '/owner/finances/car/$carId/transactions';
  static const String renterPayments = '/renter/payments';

  // Notifications and reviews (Phase 6)
  static const String renterNotifications = '/renter/notifications';
  static const String ownerNotifications = '/owner/notifications';
  static const String bookingReviewPattern = '/booking/:id/review';
  static String bookingReview(String id) => '/booking/$id/review';
  static const String carReviewsPattern = '/car/:id/reviews';
  static String carReviews(String id) => '/car/$id/reviews';
  static const String userReviewsPattern = '/user/:id/reviews';
  static String userReviews(String id) => '/user/$id/reviews';
  static const String profileReviews = '/profile/reviews';

  // Profile (Phase 1)
  static const String renterProfile = '/renter/profile';
  static const String ownerProfile = '/owner/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileAccounts = '/profile/accounts';
  static const String profileAccountsAdd = '/profile/accounts/add';
  static const String profilePayout = '/profile/payout';
  static const String profileLicence = '/profile/licence';
  static const String profileIdentity = '/profile/identity';
  static const String profileSettings = '/profile/settings';
  static const String profileAbout = '/profile/about';
  static const String profileContact = '/profile/contact';
  static const String userPattern = '/user/:id';
  static String user(String id) => '/user/$id';
}

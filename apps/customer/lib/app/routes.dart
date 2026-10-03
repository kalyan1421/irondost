abstract final class Routes {
  static const launch = '/launch';
  static const unavailable = '/unavailable';
  static const update = '/update';
  static const paused = '/paused';

  static const welcome = '/welcome';
  static const login = '/login';
  static const loginCode = '/login/code';
  static const setupName = '/setup/name';
  static const setupPin = '/setup/pin';
  static const setupDetails = '/setup/pin/details';

  /// Adding or editing an address after setup.
  static const addressPin = '/address/pin';
  static const addressDetails = '/address/details';
  static const addressSearch = '/address/search';
  static const addresses = '/account/addresses';

  /// Booking: choose items (`?service=<category slug>` picks the tab), search, then the basket.
  static const book = '/book';
  static const bookSearch = '/book/search';
  static const basket = '/basket';
  static const schedule = '/basket/schedule';
  static const checkout = '/basket/schedule/checkout';

  /// An order just placed (and paid, if online): the confirmation.
  static const orderConfirmed = '/order/:id/confirmed';
  static String confirmed(String orderId) => '/order/$orderId/confirmed';

  /// Paying an order online (just placed, or one with an amount still due).
  static const orderPay = '/order/:id/pay';
  static String pay(String orderId) => '/order/$orderId/pay';

  static const home = '/home';
  static const orders = '/orders';
  static const offers = '/offers';
  static const account = '/account';

  static const signedOutRoutes = {welcome, login, loginCode};
  static const gateRoutes = {launch, unavailable, update, paused, setupName};

  /// First-run address setup, shown until the customer has an address.
  static const setupRoutes = {setupPin, setupDetails, addressSearch};
}

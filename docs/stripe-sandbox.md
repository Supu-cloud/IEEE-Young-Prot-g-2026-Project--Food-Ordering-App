# Mobile Stripe sandbox checkout

The cart now supports multiple restaurants with one Stripe test payment. Checkout
shows separate restaurant totals and delivery fees. Payment confirmation opens
individual restaurant tracking links; each order also appears in Orders. The
backend consumes only purchased quantities once, so the app no longer clears the
whole cart for the updated checkout API. Update the backend and APK together.

New customer checkouts use the same `/payments/checkout` and
`/payments/checkout/:id/complete` APIs as the website. The backend calculates the
quote and verifies Stripe success before creating the paid order. The app never
sends card details to the Foodie backend and never marks an order paid locally.

## Build and use on Android

From the Flutter repository:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-sandbox.ps1
```

The script reads only the website's `VITE_STRIPE_PUBLISHABLE_KEY` from its existing
`.env`, requires a test publishable key, and passes it through a temporary ignored
Dart configuration file. It removes that file afterward and filters Gradle's
echoed Dart defines. It does not edit either environment file or embed a secret key.
For a different laptop IP, pass `-ApiBaseUrl http://YOUR_LAPTOP_IP:5000/api`.

Install `build/app/outputs/flutter-apk/app-debug.apk` over the existing app.
Keep the backend running and reachable from the phone. Sign in as a customer,
add available food to My cart, proceed to checkout, enter the delivery address,
review the server total, then choose **Pay with Stripe (test)**.

Use Stripe's test card `4242 4242 4242 4242`, a future expiry such as `12/34`,
and a three-digit CVC such as `123`. Never use a real card for this test.
Reference: https://docs.stripe.com/testing

The website publishable key and backend secret key must belong to the same
Stripe test environment. A restaurant must be open and linked to an approved,
verified owner, and selected menu items must be available.

## Recovery

Checkout keys and the original request are saved in secure storage before the
first request, scoped by the authenticated backend customer ID. Closing/reopening
the app or signing out does not discard that recovery record. From My cart,
choose **Resume payment / checkout**, even if the cart is empty.

The same attempt is fetched before opening PaymentSheet. Already successful
payments go directly to backend verification. Processing payments are not paid
again. Closing the sheet or a failed payment allows retrying the same attempt.
The backend commits all restaurant orders and purchased-item cleanup together.
If persistence fails, the recovery record remains so the same payment can be
verified again. Other cart items are retained.

Existing legacy pending orders are not converted by this feature. Test through
a new cart checkout. No existing order was charged or modified by implementation.
Refunds, live payments, bank payouts and webhook infrastructure are outside this
change. A checkout requiring server-side support remains recoverable rather than
being silently discarded and charged again.

## Platform setup and validation

Android uses FlutterFragmentActivity, AppCompat day/night themes, a payment return
URL and matching Java/Kotlin 17 targets for the Stripe module. iOS minimum target
is 15 (required by the installed stripe_ios SDK) with the return URL scheme; an
iOS build still requires macOS/Xcode and has not been tested here.

Automated coverage includes reuse of a checkout after a lost response and
customer isolation. The native payment sheet, test-card success/decline/3DS and
network interruption after successful payment must still be exercised on a real
device. Do not interpret a successful APK build as a completed payment demo.

## Physical Android runtime fix (September 2026)

The former exception was raised by `presentFoodiePayment` when the compile-time
`String.fromEnvironment('STRIPE_PUBLISHABLE_KEY')` did not start with `pk_test_`.
A normal `flutter run` does not import the website `.env` or remember defines
from a previous APK build. `StripeConfig` now owns test-key validation and SDK
initialization (startup, with a retry at payment time). Android already had the
required FragmentActivity, AppCompat themes and return scheme.

### Exact launch command using the existing test publishable key

Start the backend in a separate terminal from its repository with `npm.cmd run dev`.
Connect the Android phone over USB, enable USB debugging and accept its prompt.
Run from the Flutter repository:

```powershell
& "$env:LOCALAPPDATA/Android/sdk/platform-tools/adb.exe" reverse tcp:5000 tcp:5000
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-sandbox.ps1 -Run -ApiBaseUrl http://127.0.0.1:5000/api
```

The script reads only `VITE_STRIPE_PUBLISHABLE_KEY` from the sibling website `.env`.
It does not read the backend secret. Both keys must belong to the same Stripe test
account/sandbox. With multiple devices, select the same serial for `adb -s SERIAL
reverse ...` and the script's `-DeviceId SERIAL`. Repeat adb reverse after reconnecting.
For Wi-Fi, replace the API URL with the laptop's reachable LAN IP and port 5000.

Equivalent direct Flutter invocation (replace the placeholder with your publishable
test key, never a secret):

```powershell
flutter run --debug --dart-define=API_BASE_URL=http://127.0.0.1:5000/api --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_PUBLISHABLE_KEY
```

Defines require a full rebuild/relaunch; hot reload alone does not change them.
Backend Stripe variable names: `STRIPE_SECRET_KEY`; `STRIPE_WEBHOOK_SECRET` only
if using the webhook endpoint. This checkout's completion endpoint directly
retrieves and verifies the Stripe PaymentIntent, so webhooks are not needed to
complete the Wallet flow. MongoDB must support transactions (replica set/Atlas).
No `.env` files were modified.

### Fresh order with real locations

1. Sign in as the restaurant owner. Open My Restaurant / Restaurant Settings.
2. Check the textual address. Choose location on map, pan/zoom to the actual
   restaurant, tap its entrance, Confirm location, then Save Changes.
3. Reload settings and reopen the map to verify the persisted marker. Each
   restaurant in a multi-restaurant cart needs its own saved pickup point.
4. As customer, add available food to Cart. Enter the actual delivery address.
   Expand Delivery location for rider, choose the real destination on the map,
   Confirm location, then Review order and Proceed to Payment.
5. Wallet -> Pay Now -> Stripe PaymentSheet. Use the test card documented above.
   The backend verifies test mode, success, amount, currency and customer before
   saving paid orders and consuming purchased cart quantities in a transaction.
6. Confirm that confirmation/Orders shows paid orders. If the sheet is cancelled,
   a card is declined, or completion fails, retain the pending checkout and retry
   from Wallet. A payment already marked succeeded skips a second sheet.
7. Owner: accept/prepare the new order and mark it ready. Make an approved rider
   available, then assign that rider. Rider: open the assignment and View Route.
8. Check restaurant and customer markers, route polyline, distance and estimated
   travel minutes. Tap Show my location / the location control and grant permission
   for the rider marker. Repeat on the website against the same assignment.
9. If OSRM fails, both saved endpoint markers remain with an error and Retry route.
   Estimated travel time is OSRM duration, without live traffic.

New checkouts require numeric delivery latitude (-90..90) and longitude (-180..180)
together, and a restaurant pickup point. Addresses remain text. Existing schemas
and APIs already support coordinates and order snapshots; no schema migration
was needed. Shared web and Flutter coordinate controls now include map selection.
The initial Sri Lanka viewport is only a camera view: no marker or persisted point
exists until the user selects one.

### Existing test orders and saved payments

Implemented approach: update the restaurant using the picker and create a fresh
order. No backfill or database mutation assigns guessed coordinates. Historical
orders retain their snapshots and may still lack customer coordinates. Existing
payment attempts remain recoverable using their original immutable quotes. Finish
or resolve any saved payment before creating the fresh coordinate-bearing order;
do not uninstall/clear app data to discard an uncertain payment.

### Verification

- Backend: typecheck and build passed; 17 order/payment tests and 10 routing tests passed.
- Website: build passed; 8 real Leaflet tests passed, including selection, confirmation,
  cancellation, rider permission and OSRM failure. Build reports a bundle-size warning.
- Flutter: 21 payment/checkout/rider/config tests plus 1 picker interaction test passed.
- Full Flutter analyze: 51 informational existing lint findings, no errors or warnings;
  default command exits nonzero because it treats infos as fatal.
- Focused final analysis of the Stripe configuration, picker, shared coordinate
  control and their new tests passed with no issues.
- Stripe-enabled debug APK built successfully using the configured publishable test key.
- Live OSRM connectivity checked using disposable test coordinates without writing
  them to any restaurant/order: valid LineString, 662 geometry points returned.
- A physical-device PaymentSheet transaction and routing with your actual selected
  pins still require the manual sequence above. Automated tests use isolated fixtures;
  they are not evidence that a real Stripe transaction was completed.

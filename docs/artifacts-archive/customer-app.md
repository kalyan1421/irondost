# IronDost customer app
Source: https://claude.ai/artifact/Tt5QkcQxS1hRmbdsbAdWc7 · Last updated: 2026-11-23 (published version; canvas created 2026-10-02) · Archived 2026-11-23

> Design canvas (typed artifact) built on the IronDost design system: 64 interactive 390×844 phone screens covering sign-in, booking, tracking, payment, account and every error/empty state. This export keeps the on-screen text of each screen; visuals, icons and the shared app.css are not reproduced.

## Artboards (64)

**1 · Sign in and set up**

- Welcome (`Welcome.dc.html`, 390×844)
- Sign in · mobile number (`Login.dc.html`, 390×844)
- Sign in · OTP (`Otp.dc.html`, 390×844)
- Set up · name (`Profile.dc.html`, 390×844)
- Set up · pin location (`MapPin.dc.html`, 390×844)
- Set up · address details (`AddressForm.dc.html`, 390×844)

**2 · Book a pickup**

- Home (`Main.dc.html`, 390×844)
- Choose items (`Catalogue.dc.html`, 390×844)
- Basket (`Cart.dc.html`, 390×844)
- Pickup time (`Schedule.dc.html`, 390×844)
- Checkout (`Checkout.dc.html`, 390×844)
- Pickup booked (`Confirmed.dc.html`, 390×844)

**3 · Track and pay**

- Orders (`Orders.dc.html`, 390×844)
- Order tracking (`Track.dc.html`, 390×844)
- Pay what's due (`PayDue.dc.html`, 390×844)
- Notifications (`Notifications.dc.html`, 390×844)
- Offers (`Offers.dc.html`, 390×844)

**4 · Account, edge states and dark mode**

- Account (`Account.dc.html`, 390×844)
- Saved addresses (`Addresses.dc.html`, 390×844)
- Delete account (`DeleteAccount.dc.html`, 390×844)
- Orders · empty (`EmptyOrders.dc.html`, 390×844)
- Force update (`Update.dc.html`, 390×844)
- Home · dark (`HomeDark.dc.html`, 390×844)
- Order tracking · dark (`TrackDark.dc.html`, 390×844)

**5 · App states: launch, loading, offline and errors**

- Launch screen (`Splash.dc.html`, 390×844)
- Home · loading (`HomeLoading.dc.html`, 390×844)
- No internet (`Offline.dc.html`, 390×844)
- Home · offline with saved data (`OfflineBanner.dc.html`, 390×844)
- Server unavailable (`ServerDown.dc.html`, 390×844)
- Something went wrong (`ErrorGeneric.dc.html`, 390×844)
- Choose items · failed to load (`CatalogueError.dc.html`, 390×844)
- Account paused (`AccountPaused.dc.html`, 390×844)
- Notification permission (`NotifPermission.dc.html`, 390×844)

**6 · Sign-in and address states**

- Sign in · invalid number (`LoginError.dc.html`, 390×844)
- Sign in · wrong code (`OtpError.dc.html`, 390×844)
- Sign in · too many tries (`OtpLocked.dc.html`, 390×844)
- Pin location · location off (`LocationDenied.dc.html`, 390×844)
- Pin location · outside service area (`OutOfArea.dc.html`, 390×844)
- Home · switch address (`AddressPicker.dc.html`, 390×844)

**7 · Booking states**

- Search · no results (`Search.dc.html`, 390×844)
- Basket · empty (`EmptyBasket.dc.html`, 390×844)
- Basket · code expired, below minimum (`BasketIssues.dc.html`, 390×844)
- Basket · apply a code (`CouponSheet.dc.html`, 390×844)
- Pickup time · none left today (`NoSlots.dc.html`, 390×844)
- Pickup time · change delivery (`DeliverySlotSheet.dc.html`, 390×844)
- Checkout · slot just closed (`SlotTaken.dc.html`, 390×844)
- Payment · confirming (`PaymentProcessing.dc.html`, 390×844)
- Payment · failed (`PaymentFailed.dc.html`, 390×844)

**8 · Order states**

- Orders · past (`OrdersPast.dc.html`, 390×844)
- Tracking · booked, finding a partner (`TrackBooked.dc.html`, 390×844)
- Tracking · pickup running late (`TrackDelayed.dc.html`, 390×844)
- Tracking · cancel order (`CancelSheet.dc.html`, 390×844)
- Tracking · out for delivery (`TrackOutForDelivery.dc.html`, 390×844)
- Tracking · delivered (`TrackDelivered.dc.html`, 390×844)
- Tracking · cancelled (`TrackCancelled.dc.html`, 390×844)
- Items and bill (`Bill.dc.html`, 390×844)
- Payment · received (`PaySuccess.dc.html`, 390×844)

**9 · Account, help and empty states**

- Edit profile (`EditProfile.dc.html`, 390×844)
- Help and support (`Help.dc.html`, 390×844)
- Cancellation and refunds (`Legal.dc.html`, 390×844)
- Log out (`LogoutSheet.dc.html`, 390×844)
- Delete account · orders in progress (`DeleteBlocked.dc.html`, 390×844)
- Notifications · empty (`EmptyNotifications.dc.html`, 390×844)
- Offers · empty (`EmptyOffers.dc.html`, 390×844)

## 1 · Sign in and set up

### Welcome

`Welcome.dc.html` · 390×844

![IronDost](image omitted)

![](image omitted)

#### Fresh clothes, back at your door.

We pick up, iron and deliver. You choose the time.

- Pickup and delivery from your door
- Ironed and back in about a day
- Pay online or in cash at delivery

Get started

By continuing you agree to our Terms and Privacy Policy .

### Sign in · mobile number

`Login.dc.html` · 390×844

#### Enter your mobile number

We'll send a 6-digit code to verify it.

Mobile number +91 [98765 43210] Your pickup partner will call this number if needed.

Get OTP

By continuing you agree to our Terms and Privacy Policy .

### Sign in · OTP

`Otp.dc.html` · 390×844

#### Enter the code

Sent by SMS to +91 98765 43210. Change

6-digit code

4 8 2 9 1 6

Resend code in 0:24

We fill the code in for you when the SMS arrives.

Verify

### Set up · name

`Profile.dc.html` · 390×844

Step 1 of 2

#### What should we call you?

Your partner uses your name at pickup.

Full name [Priya Sharma] Email (optional) [you@example.com] For receipts. We never send marketing without asking.

Continue

### Set up · pin location

`MapPin.dc.html` · 390×844

[Search area, street or building]

Your pickup point

Step 2 of 2 · Pickup address

#### Road No. 12, Banjara Hills

Hyderabad, Telangana 500034

Move the map so the pin sits on your building.

Confirm location

### Set up · address details

`AddressForm.dc.html` · 390×844

#### Address details

Road No. 12, Banjara Hills Hyderabad 500034 Change

Flat or house number [302] Building or apartment [Sai Residency] Landmark (optional) [Near KBR Park gate] Helps your partner find you faster.

Save as

Home Work Other

Use as my default address

Save address

## 2 · Book a pickup

### Home

`Main.dc.html` · 390×844

Pickup from Home · Banjara Hills

![](image omitted)

#### Fresh clothes, back at your door.

Ironed and back in a day.

Book a pickup

##### Your order

All orders

ID001042 Being ironed Back by Sat, 4 – 8 PM

##### Services

Ironing from ₹10 Wash & iron from ₹35 Dry cleaning from ₹200

New here

20% off your first order

Up to ₹100 · Min. order ₹299

WELCOME20

Home Orders Offers Account

### Choose items

`Catalogue.dc.html` · 390×844

#### Choose items

A rough count is fine. Your partner confirms it at pickup.

Shirt / T-shirt ₹15 per piece 10

Trousers / Jeans ₹15 per piece 4

Kurta ₹20 per piece

Saree ₹50 per piece 1

Dupatta ₹10 per piece

Bedsheet (single) ₹25 per piece 2

17 items

₹310

Review basket

### Basket

`Cart.dc.html` · 390×844

#### Basket

##### Ironing

17 items

Shirt / T-shirt ₹15 each 10 ₹150

Trousers / Jeans ₹15 each 4 ₹60

Saree ₹50 each 1 ₹50

Bedsheet (single) ₹25 each 2 ₹50

Add more items

**WELCOME20** applied. You save ₹62. Change

Items (17) ₹310

WELCOME20 −₹62

Pickup & delivery Free

To pay ₹248

The final amount changes only if the count differs at pickup.

Choose pickup time

### Pickup time

`Schedule.dc.html` · 390×844

#### Pickup time

##### When should we collect?

Your partner arrives within the window you pick.

Today 2 Sat 3 Sun 4 Mon 5 Tue 6

Morning 7 – 11 AM · Closed Afternoon 11 AM – 4 PM · Closed Evening 4 – 8 PM

##### Delivery

Sat 3 Oct, 4 – 8 PM Earliest after ironing Change

Continue

### Checkout

`Checkout.dc.html` · 390×844

#### Checkout

Home 302, Sai Residency, Road No. 12, Banjara Hills · Near KBR Park gate Change

Pickup

Today, 4 – 8 PM

Delivery

Sat 3 Oct, 4 – 8 PM

##### Pay with

Pay online UPI, cards and netbanking Cash on delivery Pay the partner when your clothes come back

Items (17) ₹310

WELCOME20 −₹62

Pickup & delivery Free

To pay ₹248

Pay ₹248

Secure payment by Razorpay

### Pickup booked

`Confirmed.dc.html` · 390×844

#### Pickup booked

A partner will come today between 4 and 8 PM. We'll tell you when they're on the way.

ID001046 Paid ₹248

Pickup

Today, 4 – 8 PM

Delivery

Sat 3 Oct, 4 – 8 PM

17 items · Home, Banjara Hills

Track order Back to home

## 3 · Track and pay

### Orders

`Orders.dc.html` · 390×844

#### Orders

Active (2) Past

ID001046 Booked

10 shirts, 4 trousers, 1 saree, 2 bedsheets

Pickup

Today, 4 – 8 PM

Delivery

Sat 3 Oct, 4 – 8 PM

₹248 Paid Track

ID001042 Being ironed

8 shirts, 2 trousers, 1 kurta, 1 dupatta

Picked up

Thu 1 Oct

Delivery

Sat 3 Oct, 4 – 8 PM

₹180 ₹180 due Pay now

Home Orders Offers Account

### Order tracking

`Track.dc.html` · 390×844

#### Order ID001042

Step 3 of 5

##### Being ironed

Back by Sat 3 Oct, 4 – 8 PM

1.

Booked

Thu 1 Oct, 9:12 AM

2.

Picked up

Thu 1 Oct, 5:40 PM · 12 items counted

3.

Ironing

Ready by Sat morning

4.

Out for delivery

5.

Delivered

Sat 3 Oct, 4 – 8 PM

RK Ravi K. Picked up your clothes

₹180 is due. Pay the partner in cash or pay online now.

12 items · ₹180 8 shirts, 2 trousers, 1 kurta, 1 dupatta View bill

Pay ₹180

### Pay what's due

`PayDue.dc.html` · 390×844

#### Pay ₹180 for ID001042

12 items, ironed. Delivery Sat 3 Oct, 4 – 8 PM.

Pay online now UPI, cards and netbanking Cash at delivery Pay your partner when the clothes come back

Pay ₹180

Secure payment by Razorpay

### Notifications

`Notifications.dc.html` · 390×844

#### Notifications

Mark all read

##### Today

Partner on the way Ravi is coming to collect order ID001046. 3:52 PM Payment received ₹248 paid for order ID001046. 1:12 PM

##### Earlier

We have your clothes Order ID001042 was picked up. Back by Sat, 4 – 8 PM. Thu, 5:41 PM 20% off your first order Use WELCOME20 for up to ₹100 off. Wed, 10:00 AM Delivered Order ID001038 was delivered. Thanks for choosing IronDost. 26 Sep

### Offers

`Offers.dc.html` · 390×844

#### Offers

New here

20% off your first order

Up to ₹100 · Min. order ₹299 · Once per customer

15% off

##### 15% off orders above ₹500

Up to ₹150 · Valid till 31 Oct

FRESH15

₹50 off

##### ₹50 off orders above ₹400

Twice per customer · Valid till 15 Oct

FLAT50

Code WELCOME20 copied. Apply it in your basket.

Home Orders Offers Account

## 4 · Account, edge states and dark mode

### Account

`Account.dc.html` · 390×844

#### Account

PS Priya Sharma +91 98765 43210

Saved addresses 2 Notifications Help & support Call or email

Terms of service Privacy policy Cancellation & refunds

Log out Delete account

IronDost 1.0.0

Home Orders Offers Account

### Saved addresses

`Addresses.dc.html` · 390×844

#### Saved addresses

Home Default 302, Sai Residency, Road No. 12, Banjara Hills, Hyderabad 500034 · Near KBR Park gate

Work 4th floor, Cyber Towers, HITEC City, Hyderabad 500081 · Gate 2 reception

Add new address

### Delete account

`DeleteAccount.dc.html` · 390×844

#### Delete your account?

This removes your name, phone number and addresses. Past orders stay in our records without your details.

You'll be signed out on every device. This can't be undone.

Delete account Keep my account

### Orders · empty

`EmptyOrders.dc.html` · 390×844

#### Orders

Active Past

![](image omitted)

##### No orders yet

Book a pickup and we'll collect your clothes.

Book a pickup

Home Orders Offers Account

### Force update

`Update.dc.html` · 390×844

![](image omitted)

#### Time to update

This version of IronDost is no longer supported. Updating takes a minute and keeps you signed in.

Update now

You have 1.0.0 · Latest is 1.2.0

### Home · dark

`HomeDark.dc.html` · 390×844

[Embeds the "Main" artboard]

### Order tracking · dark

`TrackDark.dc.html` · 390×844

[Embeds the "Track" artboard]

## 5 · App states: launch, loading, offline and errors

### Launch screen

`Splash.dc.html` · 390×844

![IronDost](image omitted) ![IronDost. Wash, iron, deliver.](image omitted)

### Home · loading

`HomeLoading.dc.html` · 390×844

Home Orders Offers Account

### No internet

`Offline.dc.html` · 390×844

#### You're offline

Check your Wi-Fi or mobile data, then try again. Your basket is saved on this phone.

Try again

### Home · offline with saved data

`OfflineBanner.dc.html` · 390×844

[Embeds the "Main" artboard]

You're offline. Showing what we saved. Retry

### Server unavailable

`ServerDown.dc.html` · 390×844

#### We'll be right back

IronDost isn't responding right now. Your orders and payments are safe. Please try again in a few minutes.

Error 503 · Service unavailable

Try again [Call +91 90632 90012](tel:+919063290012)

### Something went wrong

`ErrorGeneric.dc.html` · 390×844

#### Something went wrong

We couldn't open this page. Try again, and if it keeps happening, let us know.

Error 500 · We've been notified

Try again Contact support

### Choose items · failed to load

`CatalogueError.dc.html` · 390×844

#### Choose items

##### Couldn't load prices

Check your connection and try again. Items already in your basket are kept.

Try again

### Account paused

`AccountPaused.dc.html` · 390×844

#### Your account is paused

You can't book pickups right now. Call or email us and we'll sort it out.

Signed in as +91 98765 43210

[Call +91 90632 90012](tel:+919063290012) [Email support](mailto:kalyan91333@gmail.com) Log out

### Notification permission

`NotifPermission.dc.html` · 390×844

#### Know when we're at your door

We'll tell you when a partner is on the way, when your clothes are ready and when they're delivered. Offers only if you want them.

Turn on notifications Not now

## 6 · Sign-in and address states

### Sign in · invalid number

`LoginError.dc.html` · 390×844

#### Enter your mobile number

We'll send a 6-digit code to verify it.

Mobile number +91 [98765 4321] Enter a 10-digit mobile number.

Get OTP

By continuing you agree to our Terms and Privacy Policy .

### Sign in · wrong code

`OtpError.dc.html` · 390×844

#### Enter the code

Sent by SMS to +91 98765 43210. Change

6-digit code

4 8 2 9 1 7

That code is incorrect. Check the SMS and try again.

Didn't get it? Resend code

Try again

### Sign in · too many tries

`OtpLocked.dc.html` · 390×844

#### Too many tries

To keep your account safe, we've paused codes for +91 98765 43210. You can ask for a new one in a little while.

Try again in 29:41

Use a different number Contact support

### Pin location · location off

`LocationDenied.dc.html` · 390×844

[Road No. 12 Banjara]

Location is off, so search for your address instead. Turn on

- **Road No. 12**, **Banjara** Hills Hyderabad, Telangana
- **Road No. 12** Junction, **Banjara** Hills Hyderabad, Telangana 500034
- **Banjara** Hills **Road No. 12** Bus Stop Hyderabad, Telangana

Can't find it? Pick the nearest street, then move the pin.

### Pin location · outside service area

`OutOfArea.dc.html` · 390×844

[Search area, street or building]

Outside our area

#### We're not in Gachibowli yet

ISB Road, Gachibowli, Hyderabad 500032

We can't pick up from here yet. Try another address, or save this one and book once we reach your area.

Change location Save address anyway

### Home · switch address

`AddressPicker.dc.html` · 390×844

#### Pick up from

Home 302, Sai Residency, Road No. 12, Banjara Hills Work 4th floor, Cyber Towers, HITEC City Parents 12, ISB Road, Gachibowli Not in our area yet

Add new address

## 7 · Booking states

### Search · no results

`Search.dc.html` · 390×844

[curtain]

#### No items match "curtain"

Try a different word, like shirt or saree. Need something we don't list? Call us and we'll help.

[Call +91 90632 90012](tel:+919063290012)

##### Popular

Shirt / T-shirt Saree Bedsheet Suit (2 piece)

### Basket · empty

`EmptyBasket.dc.html` · 390×844

#### Basket

##### Your basket is empty

Add the clothes you want ironed, washed or dry-cleaned. A rough count is fine.

Choose items

### Basket · code expired, below minimum

`BasketIssues.dc.html` · 390×844

#### Basket

##### Ironing

7 items

Shirt / T-shirt ₹15 each 6 ₹90

Saree ₹50 each 1 ₹50

Add more items

FIRST50 This code has expired Change

Add **₹59** more to book. The minimum order is ₹199.

Items (7) ₹140

Pickup & delivery Free

To pay ₹140

Add ₹59 more

### Basket · apply a code

`CouponSheet.dc.html` · 390×844

#### Apply a code

Promo code [WELCOME] Apply

##### Available for you

WELCOME20 20% off your first order Up to ₹100 · Min. order ₹299 Apply

FRESH15 15% off orders above ₹500 Add ₹190 more to use this Apply

### Pickup time · none left today

`NoSlots.dc.html` · 390×844

#### Pickup time

##### When should we collect?

Today 2 Sat 3 Sun 4 Mon 5 Tue 6

Morning 7 – 11 AM · Closed Afternoon 11 AM – 4 PM · Closed Evening 4 – 8 PM · Closed

Today's pickups have closed. The earliest is tomorrow morning. Pick Sat, 7 – 11 AM

Continue

### Pickup time · change delivery

`DeliverySlotSheet.dc.html` · 390×844

#### Delivery time

Ironing takes about 20 hours, so earlier windows aren't available.

Sat 3 Sun 4 Mon 5 Tue 6 Wed 7

Morning 7 – 11 AM · Too soon Afternoon 11 AM – 4 PM · Too soon Evening 4 – 8 PM

Done

### Checkout · slot just closed

`SlotTaken.dc.html` · 390×844

#### That slot just closed

Today's evening pickup isn't available any more. Pick another time. Your basket and code are kept, and you haven't been charged.

Pick another time Close

### Payment · confirming

`PaymentProcessing.dc.html` · 390×844

#### Confirming your payment

This takes a few seconds. Please keep the app open.

Order ID001046

Amount ₹248

Paid with UPI

Secure payment by Razorpay

### Payment · failed

`PaymentFailed.dc.html` · 390×844

#### Payment didn't go through

Your bank declined it. If any money left your account, your bank returns it automatically.

Your pickup is still booked for today, 4 – 8 PM. Order ID001046 .

Try again · ₹248 Pay cash at delivery instead

## 8 · Order states

### Orders · past

`OrdersPast.dc.html` · 390×844

#### Orders

Active (2) Past

ID001038 Delivered

6 shirts, 2 trousers · Sat 26 Sep

₹120 Paid in cash Details

ID001035 Cancelled

Cancelled before pickup · Wed 23 Sep

₹200 Nothing charged Details

ID001031 Delivered

4 shirts, 1 saree · Sat 19 Sep

₹110 Paid online Details

Home Orders Offers Account

### Tracking · booked, finding a partner

`TrackBooked.dc.html` · 390×844

#### Order ID001046

Step 1 of 5

##### Booked

Pickup today, 4 – 8 PM

1.

Booked

Finding a partner near you

2.

Picked up

Today, 4 – 8 PM

3.

Ironing

4.

Out for delivery

5.

Delivered

Sat 3 Oct, 4 – 8 PM

You'll see your partner's name and number here once they accept.

17 items · ₹248 Paid online View bill

Cancel order

Free to cancel until your clothes are picked up.

### Tracking · pickup running late

`TrackDelayed.dc.html` · 390×844

#### Order ID001046

Step 1 of 5

##### Pickup running late

Window today, 4 – 8 PM

All our partners nearby are busy. We're still trying and will call you if we can't make it by 8 PM. [Call us](tel:+919063290012) Cancel order

1.

Booked

Looking for a partner since 3:00 PM

2.

Picked up

Today, 4 – 8 PM

3.

Ironing

4.

Out for delivery

5.

Delivered

Sat 3 Oct, 4 – 8 PM

### Tracking · cancel order

`CancelSheet.dc.html` · 390×844

#### Cancel this order?

Tell us why (optional). It helps us improve.

I won't be at home I booked by mistake The time doesn't suit me Something else

You paid ₹248 online. It's refunded in full to the same account within 7–14 business days.

Cancel order Keep order

### Tracking · out for delivery

`TrackOutForDelivery.dc.html` · 390×844

#### Order ID001042

Step 4 of 5

##### Out for delivery

Arriving today, 4 – 8 PM

RK Ravi K. Bringing your clothes back

1.

Booked

Thu 1 Oct, 9:12 AM

2.

Picked up

Thu 1 Oct, 5:40 PM

3.

Ironing

Ready Sat, 11:20 AM

4.

Out for delivery

Ravi left at 4:10 PM

5.

Delivered

₹180 is due. Pay Ravi in cash at the door, or pay online now.

Pay ₹180 online

### Tracking · delivered

`TrackDelivered.dc.html` · 390×844

#### Order ID001042

##### Delivered

Sat 3 Oct, 5:32 PM · by Ravi K.

Picked up Thu 1 Oct, 5:40 PM

Items 12, ironed

Paid ₹180 in cash

Items and bill Something wrong with an item?

Book the same again

### Tracking · cancelled

`TrackCancelled.dc.html` · 390×844

#### Order ID001046

Cancelled

##### You cancelled this order

Fri 2 Oct, 2:14 PM · "I booked by mistake"

Your ₹248 refund is on its way to the account you paid from. Refunds take 7–14 business days.

Was booked for Fri 2 Oct, 4 – 8 PM

Items 17 · Ironing

Amount ₹248 · refund pending

Book again

### Items and bill

`Bill.dc.html` · 390×844

#### Items and bill

ID001042 Paid

Picked up Thu 1 Oct · Delivered Sat 3 Oct

##### Ironing

Counted at pickup

Shirt / T-shirt 8 × ₹15 ₹120

Trousers / Jeans 2 × ₹15 ₹30

Kurta 1 × ₹20 ₹20

Dupatta 1 × ₹10 ₹10

Items (12) ₹180

Pickup & delivery Free

Total ₹180

Paid in cash · Sat 3 Oct ₹180

Due ₹0

### Payment · received

`PaySuccess.dc.html` · 390×844

#### ₹180 paid

Thanks! Order ID001042 is fully paid. Nothing to pay at the door.

Paid with UPI

Payment ID pay_PZ3k9xT1

When Sat 3 Oct, 4:22 PM

Back to order

## 9 · Account, help and empty states

### Edit profile

`EditProfile.dc.html` · 390×844

#### Edit profile

PS Full name [Priya Sharma] Email (optional) [you@example.com] For receipts.

Mobile number +91 98765 43210 Your number signs you in. To change it, contact support .

Save changes

### Help and support

`Help.dc.html` · 390×844

#### Help and support

##### Talk to us

[Call us +91 90632 90012](tel:+919063290012) [Email us kalyan91333@gmail.com](mailto:kalyan91333@gmail.com)

##### Common questions

When will my clothes come back?

You pick the delivery window at checkout. The earliest is about 20 hours after pickup, so a morning pickup usually comes back the next evening.

Can I change or cancel a pickup?

What if an item is damaged or missing?

How do refunds work?

Cancellation and refunds Terms of service

### Cancellation and refunds

`Legal.dc.html` · 390×844

#### Cancellation and refunds

IronDost is run by Cloud Ironing Factory Private Limited. Last updated December 2025.

##### 1. Paying for your order

Pay online (UPI, cards or netbanking) or in cash at delivery. The full amount is due by the time your clothes are delivered.

##### 2. Cancelling

- **Before pickup:** cancel free in the app. Anything you paid online is refunded in full.
- **After pickup, before ironing starts:** call us and we'll cancel with a full refund.
- **Once ironing has started:** the order can't be cancelled or refunded.

##### 3. Refunds

We refund when we couldn't provide the service, or as agreed when we resolve a complaint. Approved refunds reach the payment method you used within 7–14 business days.

### Log out

`LogoutSheet.dc.html` · 390×844

#### Log out of IronDost?

Your basket stays on this phone. You'll need a code by SMS to sign in again, and this phone stops getting order updates.

Log out Stay signed in

### Delete account · orders in progress

`DeleteBlocked.dc.html` · 390×844

#### Finish your orders first

You have 2 orders in progress. You can delete your account once they're delivered or cancelled.

View orders Close

### Notifications · empty

`EmptyNotifications.dc.html` · 390×844

#### Notifications

##### You're all caught up

Updates on your orders and payments will appear here.

### Offers · empty

`EmptyOffers.dc.html` · 390×844

#### Offers

##### No offers right now

New offers show up here, and we'll let you know when one starts.

Home Orders Offers Account

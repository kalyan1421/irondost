# Running pickups and deliveries from the admin

There is no partner (driver) app yet, so staff move every order along from the admin console. This is the day-to-day routine.
Status names below are the button labels in the admin.

## One-time setup

- **Delivery partners.** Add each person who collects or delivers under *Delivery partners* (name and phone). They never sign in
  anywhere; the entry only lets you assign orders to them. The dialog's note about a "partner app" does not apply yet.
- **Staff.** Add everyone else who uses the admin under *Staff* (super admin only).
- **Business settings.** Set the delivery fee, the minimum order and the free-delivery limit. They start at ₹0.
- **Prices.** Under *Services & prices*, check every price. Nothing placeholder should be live.

## An order, step by step

| Step | In the admin | What the customer sees |
|---|---|---|
| Order placed | Appears under *Orders* → *Pickups*. Automatic dispatch finds nobody (no one is online), so it is flagged *Needs a partner* and retried every 5 minutes. | "Order placed" |
| Assign pickup | Open the order → *Partners* card → assign the person collecting. | "Pickup partner assigned" |
| Clothes collected | **Mark picked up** | "Clothes picked up" |
| Count the clothes | If the count differs, change the items (*Items* card). The total is repriced and the customer is told the new total. If they had already paid more, staff get a *Refund needed* alert. | "Your order total changed" |
| At the workshop | **Received at workshop** | "Being ironed" |
| Done | **Ready for delivery** | "Ready for delivery" |
| Assign delivery | *Partners* card → assign the person delivering. | none |
| On the way | **Mark out for delivery** | "Out for delivery" |
| Handed over | **Mark delivered**. If money is still due, a box asks whether cash was collected; leave it ticked when it was. | "Delivered", and "Payment received" for cash |

## Money

- **Cash on delivery:** tick *Cash collected at delivery* in the *Mark delivered* box. It records the cash and marks the order paid.
  If the customer will pay later, leave it unticked and record the payment later in the *Payments* card.
- **Paid online:** nothing to do. The *Payments* card shows it.
- **A balance after the items changed:** the customer is told to pay in the app or in cash at delivery.
- **Refunds:** *Orders* → **Refund due** lists every order where the customer is owed money back (cancelled after paying, or the
  total was reduced below what they paid). Open the order and refund it. The dashboard shows the same count.

## Alerts

*Alerts* in the sidebar lists what the system sends staff: new orders, orders with no partner, refunds needed or failed. The red
badge is the unread count. The dashboard also shows *No partner found* and *Customers are owed money* when they apply.

## End of day

1. Dashboard shows no *No partner found* and no refunds owed.
2. *Orders* → *Delivered*: any order showing *Unpaid* needs its payment recorded.
3. *Orders* → *Active*: nothing stuck at the same status since yesterday.

## Other things you can do

- **Cancel** an order from its page (the customer and any partner are told). If they had paid, it appears under *Refund due*.
- **Make an old app update** (super admin): *App versions*. Customers below the minimum must update before using the app.
- **See who changed what** (super admin): *Audit log*.

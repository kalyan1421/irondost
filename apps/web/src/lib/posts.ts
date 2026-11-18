/**
 * Blog posts. Plain data, rendered by `app/blog/[slug]/page.tsx`.
 *
 * Rules (from docs/marketing/blog-and-search-plan.md): answer first, one job per post, no competitor names,
 * no "best" or "cheapest", no invented customers or numbers. Prices are left out on purpose: they live in the app
 * and change; a wrong price on a page is worse than none. Update `updated` whenever a post changes.
 */

export type PostSection = {
  heading: string;
  paragraphs?: string[];
  bullets?: string[];
  steps?: { title: string; body: string }[];
};

export type Post = {
  slug: string;
  title: string;
  /** Meta description: 150 to 160 characters, says what the reader gets. */
  description: string;
  published: string;
  updated: string;
  /** The opening paragraph. It answers the question in the title on its own. */
  answer: string;
  sections: PostSection[];
  faq?: { q: string; a: string }[];
  /** Slugs of the guides a reader of this one needs next, in order. */
  related: string[];
  /** Lead image under /redesign (stand-in photos until real ones are shot). Alt text says what it shows. */
  image: { src: string; alt: string };
};

const areas =
  "LB Nagar, Dilsukhnagar, Chaitanyapuri, Saroornagar, Mansoorabad, Nagole, Bandlaguda, Vanasthalipuram, Karmanghat, Champapet, Santosh Nagar and Saidabad";

export const posts: Post[] = [
  {
    slug: "how-doorstep-ironing-pickup-works",
    image: { src: "doorstep-handover", alt: "A cloth bag of clothes being handed over at an apartment door for an IronDost pickup." },
    related: ["areas-we-serve-around-lb-nagar", "will-laundry-bill-change-after-pickup", "silk-saree-dry-cleaning-what-to-tell-us"],
    title: "How doorstep ironing pickup works in LB Nagar, step by step",
    description:
      "What happens after you book an IronDost pickup around LB Nagar: choosing items, the three pickup windows, the count at your door, delivery and payment.",
    published: "2026-11-19",
    updated: "2026-11-19",
    answer:
      "You choose your clothes and a pickup window in the IronDost app, a partner collects them from your door and confirms the count with you, and the clothes come back pressed, usually the next day. You see every price and the total before you confirm, and you can pay online or in cash at delivery.",
    sections: [
      {
        heading: "The five steps",
        steps: [
          {
            title: "Add your address",
            body: "The app checks whether your address is inside our area when you save it. We currently pick up within 6 km of LB Nagar Circle.",
          },
          {
            title: "Choose your items",
            body: "Pick ironing, wash and iron, or dry cleaning, and add a rough count of each item. A rough count is fine; it is checked at pickup.",
          },
          {
            title: "Pick a window",
            body: "There are three pickup windows every day of the week: 7 am to 11 am, 11 am to 4 pm, and 4 pm to 8 pm. When a window is booked up the app shows it as Full, so pick the next one.",
          },
          {
            title: "Hand over at your door",
            body: "Your partner counts the clothes with you. If the count differs from what you entered, the order is updated before anything is processed, and you see the new total.",
          },
          {
            title: "Back at your door",
            body: "Clothes come back pressed and packed, usually the next day. Pay online with UPI, a card or netbanking, or in cash when they arrive.",
          },
        ],
      },
      {
        heading: "Can I follow the order?",
        paragraphs: [
          "Yes. The order screen in the app shows each step from booking to delivery, and you get a notification when your clothes are picked up, being ironed, and on their way back. Your order number starts with ID; keep it handy if you call us.",
        ],
      },
      {
        heading: "Can I change or cancel?",
        paragraphs: [
          "You can cancel in the app until your clothes are picked up. After pickup, call or WhatsApp us and we will help. If you paid online and the order is cancelled, the money goes back to the method you paid with.",
        ],
      },
      {
        heading: "What should I tell you before pickup?",
        bullets: [
          "Any stain you want us to look at, and what caused it if you know.",
          "Delicate parts: zari, embroidery, beadwork, sequins.",
          "Anything that may lose colour.",
          "A photo on WhatsApp helps for anything unusual.",
        ],
      },
    ],
    faq: [
      {
        q: "Do I need the app to book?",
        a: "The app is the quickest way, because it shows prices and open windows. You can also call or WhatsApp us and we will book it for you.",
      },
      {
        q: "Do I have to be home for pickup?",
        a: "Someone needs to hand over the clothes and agree the count. It can be anyone at home.",
      },
    ],
  },
  {
    slug: "areas-we-serve-around-lb-nagar",
    image: { src: "delivery-door", alt: "A suit in a clear cover and a bundle of pressed clothes handed back at a customer's door." },
    related: ["how-doorstep-ironing-pickup-works", "ironing-for-pg-and-hostel-residents-dilsukhnagar"],
    title: "Areas we serve around LB Nagar, with PIN codes",
    description:
      "IronDost picks up within 6 km of LB Nagar Circle, Hyderabad. See the 12 localities and 7 PIN codes we serve, and what to do if you live just outside.",
    published: "2026-11-19",
    updated: "2026-11-19",
    answer: `IronDost picks up and delivers within 6 km of LB Nagar Circle in Hyderabad, in seven PIN codes: 500074, 500060, 500035, 500068, 500070, 500079 and 500059. That covers ${areas}.`,
    sections: [
      {
        heading: "Localities by PIN code",
        bullets: [
          "500074: LB Nagar",
          "500060: Dilsukhnagar, Chaitanyapuri",
          "500035: Saroornagar, HUDA Complex",
          "500068: Mansoorabad, Nagole, Bandlaguda",
          "500070: Vanasthalipuram",
          "500079: Karmanghat, Champapet",
          "500059: Santosh Nagar, Saidabad",
        ],
      },
      {
        heading: "How do I know my address is covered?",
        paragraphs: [
          "Add your address in the app. It checks the distance from LB Nagar Circle and the PIN code together, and tells you straight away. Both have to match: an address in a listed PIN code but more than 6 km away is outside, and so is an address within 6 km in a PIN code we do not list.",
        ],
      },
      {
        heading: "I live just outside. Can you still come?",
        paragraphs: [
          "Not yet. Malakpet, Uppal and Balapur are just beyond the line today. You can still create an account and save your address; booking opens in more areas as we expand.",
        ],
      },
    ],
    faq: [
      {
        q: "Is there a pickup charge?",
        a: "The app shows every charge before you confirm the order. Nothing is added afterwards except when the count at pickup differs from what you entered.",
      },
    ],
  },
  {
    slug: "silk-saree-dry-cleaning-what-to-tell-us",
    image: { src: "saree-zari", alt: "Hands folding a maroon silk saree with the gold zari border turned inside." },
    related: ["how-doorstep-ironing-pickup-works", "will-laundry-bill-change-after-pickup"],
    title: "Silk saree dry cleaning: four things to tell us before you hand it over",
    description:
      "Before giving a silk saree for dry cleaning, tell us about stains, zari and embroidery, colour that may run, and send a photo. It takes a minute.",
    published: "2026-11-19",
    updated: "2026-11-19",
    answer:
      "Before you hand over a silk saree, tell us four things: every stain and what caused it, where the zari, embroidery or beadwork is, whether the colour has run before, and send a photo of anything you are worried about. It takes a minute and it decides how the saree is handled.",
    sections: [
      {
        heading: "1. Show us every stain",
        paragraphs: [
          "Point to each mark and say what it is and how old it is, if you know: oil, turmeric, food, lipstick, mehndi. Older stains are harder. We will try to remove stains, but we cannot promise it, and we would rather tell you that before than after.",
        ],
      },
      {
        heading: "2. Point out the delicate parts",
        paragraphs: [
          "Zari borders, embroidery, beadwork and sequins need gentler handling and a lower iron. Tell us where they are, especially if the work is on the pallu only.",
        ],
      },
      {
        heading: "3. Say if the colour may run",
        paragraphs: [
          "New sarees and deep colours can bleed. If it has run before, tell us and we keep it apart from everything else.",
        ],
      },
      {
        heading: "4. Send a photo",
        paragraphs: [
          "A quick picture of the stain or the border on WhatsApp means nothing gets missed between your door and the table.",
        ],
      },
      {
        heading: "Ironing only?",
        paragraphs: [
          "If the saree is clean and only needs pressing, choose saree ironing instead of dry cleaning in the app. Tell us about zari and embroidery all the same.",
        ],
      },
    ],
    faq: [
      {
        q: "Can every stain be removed?",
        a: "No. Some marks do not come out, especially old ones or ones that have been ironed over. We will try and tell you honestly what is left.",
      },
      {
        q: "How long does dry cleaning take?",
        a: "Longer than ironing. Ask us when you book if you need it back for a wedding or function, and book early.",
      },
    ],
  },
  {
    slug: "ironing-for-pg-and-hostel-residents-dilsukhnagar",
    image: { src: "finished-bed", alt: "Pressed shirts and folded clothes laid out on a bed, ready for the week." },
    related: ["areas-we-serve-around-lb-nagar", "will-laundry-bill-change-after-pickup", "how-doorstep-ironing-pickup-works"],
    title: "Ironing for PG and hostel residents in Dilsukhnagar and LB Nagar",
    description:
      "No iron in your PG? IronDost picks up shirts and trousers from PGs and hostels around Dilsukhnagar and LB Nagar, with no minimum order, and returns them pressed.",
    published: "2026-11-19",
    updated: "2026-11-19",
    answer:
      "If you live in a PG or hostel around Dilsukhnagar or LB Nagar, you can book ironing pickup from your door in the IronDost app, pay per piece, and get your clothes back pressed, usually the next day. There is no minimum number of clothes.",
    sections: [
      {
        heading: "Why it works for a PG",
        bullets: [
          "Per-piece prices, shown before you confirm. Five shirts is a normal order.",
          "Pickup in the evening window, 4 pm to 8 pm, after college or work.",
          "Pay by UPI in the app or in cash at delivery.",
          "Your order and its status are in your own account, not in a shared notebook.",
        ],
      },
      {
        heading: "A week of shirts, sorted on Sunday",
        paragraphs: [
          "Most people book once a week: shirts and trousers for the coming week, picked up on Sunday evening and back on Monday. Add a kurta or a saree when there is an occasion.",
        ],
      },
      {
        heading: "Booking for the whole PG",
        paragraphs: [
          "Each person can book their own order from the same address. If you manage a PG and want one regular pickup for residents, call or WhatsApp us and we will work out a day that suits you.",
        ],
      },
      {
        heading: "Is my PG inside the area?",
        paragraphs: [
          "We pick up within 6 km of LB Nagar Circle, in PIN codes 500074, 500060, 500035, 500068, 500070, 500079 and 500059. The app checks your address when you add it.",
        ],
      },
    ],
  },
  {
    slug: "will-laundry-bill-change-after-pickup",
    image: { src: "screen-schedule", alt: "The IronDost app screen for choosing pickup and delivery times before confirming an order." },
    related: ["how-doorstep-ironing-pickup-works", "areas-we-serve-around-lb-nagar"],
    title: "Will the laundry bill change after pickup? What to check before you book",
    description:
      "With IronDost the price is fixed per piece and shown before you confirm. The only thing that can change the total is the count at pickup. Here is how it works.",
    published: "2026-11-19",
    updated: "2026-11-19",
    answer:
      "The total changes only if the number of clothes counted at pickup is different from what you entered. Prices are per piece and shown in the app before you confirm, and the count is agreed with you at your door, before anything is washed or pressed.",
    sections: [
      {
        heading: "Why bills change elsewhere",
        paragraphs: [
          "Bills usually change when the price was not clear at the start: a rate given by weight, a count done later at the shop, or extra charges named only at delivery. All three leave you with a number you never agreed to.",
        ],
      },
      {
        heading: "How IronDost keeps the total fixed",
        steps: [
          { title: "Per-piece prices", body: "Every item has its price in the app. You see the total before you confirm." },
          {
            title: "The count happens at your door",
            body: "Your partner counts the clothes with you at pickup. If the count differs, the order is updated then and you see the new total.",
          },
          { title: "Nothing is added later", body: "No charge appears at delivery that you did not see in the app." },
        ],
      },
      {
        heading: "What to check before you book",
        bullets: [
          "Count your clothes roughly by type: shirts, trousers, sarees, bedsheets.",
          "Pick the right service for each item: ironing only, wash and iron, or dry cleaning.",
          "Check the total and the pickup window before you confirm.",
          "Keep anything you are unsure about aside and ask at pickup.",
        ],
      },
    ],
    faq: [
      {
        q: "What if a coupon applies?",
        a: "Apply it in the app before you confirm. The discounted total is what you pay, adjusted only if the count changes.",
      },
      {
        q: "What if something is missing or damaged?",
        a: "Tell us within 48 hours of delivery with your order number, and we will sort it out.",
      },
    ],
  },
];

export const getPost = (slug: string) => posts.find((p) => p.slug === slug);

export const formatDate = (iso: string) =>
  new Date(`${iso}T00:00:00+05:30`).toLocaleDateString("en-IN", { day: "numeric", month: "long", year: "numeric", timeZone: "Asia/Kolkata" });

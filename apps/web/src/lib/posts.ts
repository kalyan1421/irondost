/**
 * Blog posts. Plain data, rendered by `app/blog/[slug]/page.tsx`.
 *
 * Rules (from docs/marketing/blog-and-search-plan.md): answer first, one job per post, no competitor names,
 * no "best" or "cheapest", no invented customers or numbers. Prices are left out on purpose: they live in the app
 * and change; a wrong price on a page is worse than none. Update `updated` whenever a post changes.
 */

import { priceList } from "@/lib/prices";

const shirtItem = priceList.find((c) => c.slug === "ironing")?.items.find((i) => i.name.toLowerCase().startsWith("shirt"));
const shirtNow = shirtItem ? (shirtItem.offer ?? shirtItem.price) : 0;
const shirtLine = shirtItem?.offer ? `₹${shirtItem.offer} on the current offer (₹${shirtItem.price} regular)` : `₹${shirtNow}`;
const priceOf = (category: string, name: string) => {
  const i = priceList.find((c) => c.slug === category)?.items.find((x) => x.name.toLowerCase().startsWith(name.toLowerCase()));
  return i ? (i.offer ?? i.price) : 0;
};
const washShirtNow = priceOf("wash-and-iron", "shirt");
const suitNow = priceOf("dry-cleaning", "suit");

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
  "LB Nagar, Dilsukhnagar, Chaitanyapuri, Saroornagar, Kothapet, HUDA Complex, Mansoorabad, Nagole, Bandlaguda, Vanasthalipuram, Karmanghat, Champapet, Santosh Nagar and Saidabad";

export const posts: Post[] = [
  {
    slug: "how-to-pack-your-laundry-bag-for-pickup",
    image: { src: "doorstep-handover", alt: "A cloth bag of clothes being handed over at an apartment door for an IronDost laundry pickup." },
    related: ["wash-and-iron-or-dry-clean-which-fabric", "will-laundry-bill-change-after-pickup", "how-doorstep-ironing-pickup-works"],
    title: "How to pack your laundry bag for pickup",
    description:
      "Empty the pockets, keep dry cleaning apart, set aside anything that may lose colour, and count roughly by type. Five minutes before an IronDost laundry pickup.",
    published: "2026-11-20",
    updated: "2026-11-20",
    answer:
      "Empty every pocket, keep anything for dry cleaning in a separate bag, set aside new or dark clothes that may lose colour, and count your clothes roughly by type. Then show your partner any stains at the door. It takes about five minutes and helps your laundry come back the way you want it.",
    sections: [
      {
        heading: "1. Empty the pockets",
        paragraphs: [
          "Check every pocket for pens, cash, cards, keys, tissues and earphones. A pen or a tissue left in one shirt can mark or cover a whole load. Take off belts, brooches and anything that can be removed.",
        ],
      },
      {
        heading: "2. Keep each service apart",
        bullets: [
          "Laundry (wash and iron): everyday shirts, T-shirts, trousers, jeans and bedsheets.",
          "Ironing only: clean clothes that just need pressing.",
          "Dry cleaning: suits, blazers, silk sarees, and anything with zari, embroidery, beadwork or sequins.",
        ],
        paragraphs: ["One bag per service makes the count at your door quick and stops a silk saree ending up with the laundry."],
      },
      {
        heading: "3. Set aside anything that may lose colour",
        paragraphs: [
          "New clothes and deep colours, especially reds, dark blues and new denim, can bleed in their first washes. Keep them on top of the bag and tell your partner, so we know to keep them apart from lighter clothes.",
        ],
      },
      {
        heading: "4. Point out stains",
        paragraphs: [
          "Show your partner each stain at the door and say what it is if you know: oil, curry, ink, mud. We will try to remove it, but we cannot promise it. Stains that have been washed and dried at home before are harder to shift.",
        ],
      },
      {
        heading: "5. Count roughly by type",
        paragraphs: [
          "In the app, add a rough count of each item: shirts, trousers, bedsheets. It does not have to be exact. Your partner counts the clothes with you at the door, and the total changes only if the count is different from what you entered.",
        ],
      },
    ],
    faq: [
      {
        q: "Do I have to count exactly?",
        a: "No. A rough count is fine. The count is agreed with you at your door, before anything is washed, and you see the new total if it changes.",
      },
      {
        q: "Can I send towels or home clothes?",
        a: "Yes, as Wash & Fold: washed and folded, no ironing. Its prices are not on the rate card yet, so ask us before you book.",
      },
    ],
  },
  {
    slug: "wash-and-iron-or-dry-clean-which-fabric",
    image: { src: "saree-zari", alt: "Hands folding a maroon silk saree with a gold zari border, the kind of piece that goes to dry cleaning." },
    related: ["how-to-pack-your-laundry-bag-for-pickup", "silk-saree-dry-cleaning-what-to-tell-us"],
    title: "Wash & iron or dry clean: which does this fabric need?",
    description:
      "Cotton, denim and everyday synthetics usually go in the wash. Silk, wool suits and anything with zari or embroidery go to dry cleaning. Check the care label first.",
    published: "2026-11-20",
    updated: "2026-11-20",
    answer:
      "Everyday cotton, polycotton, denim and most synthetic clothes can be washed and ironed. Silk sarees, wool suits and blazers, and anything with zari, embroidery, beadwork or sequins should be dry-cleaned. The care label inside the garment is the first thing to check, and when it is missing or unclear, ask us before pickup.",
    sections: [
      {
        heading: "Read the care label",
        bullets: [
          "A tub of water: the garment can be washed. A number inside it is the highest water temperature in °C.",
          "A tub with a hand in it: hand wash only. Tell us when you hand it over.",
          "A crossed-out tub: do not wash.",
          "A circle: dry clean. \"Dry clean only\" in words means the same.",
        ],
      },
      {
        heading: "Usually wash and iron",
        bullets: [
          "Cotton and polycotton shirts and T-shirts",
          "Trousers and jeans",
          "Everyday cotton kurtas and salwars",
          "Bedsheets and pillow covers",
        ],
        paragraphs: [`Wash and iron is per piece, from ₹${washShirtNow} for a shirt, and you see every price in the app before you confirm.`],
      },
      {
        heading: "Usually dry cleaning",
        bullets: [
          "Suits, blazers and other tailored jackets",
          "Silk sarees and silk blouses",
          "Wool and wool-blend clothes",
          "Anything with zari, embroidery, beadwork, sequins or mirror work",
          "Lehengas and heavy occasion wear",
        ],
        paragraphs: [
          `Dry cleaning is priced higher than washing: a two-piece suit is ₹${suitNow}. The full list is on our prices page.`,
        ],
      },
      {
        heading: "Only needs pressing?",
        paragraphs: [
          "If a garment is already clean and just creased, choose ironing instead. It costs less than wash and iron, and it suits most clothes, including sarees. Tell us about zari or embroidery so it is pressed at a lower heat.",
        ],
      },
      {
        heading: "Not sure?",
        paragraphs: [
          "Send a photo of the garment and its label on WhatsApp before pickup, or ask your partner at the door. We would rather check first than put the wrong thing in a machine.",
        ],
      },
    ],
    faq: [
      {
        q: "Can a silk saree go in the wash?",
        a: "We send silk sarees to dry cleaning, not the machine. If it is clean and only creased, saree ironing is enough.",
      },
      {
        q: "What if there is no care label?",
        a: "Tell us what the fabric is if you know, or send a photo. If in doubt, dry cleaning is the safer choice for anything delicate or embellished.",
      },
    ],
  },
  {
    slug: "monsoon-laundry-why-clothes-wont-dry",
    image: { src: "finished-bed", alt: "Pressed shirts and folded clothes laid out on a bed, dry and ready to wear." },
    related: ["how-to-pack-your-laundry-bag-for-pickup", "wash-and-iron-or-dry-clean-which-fabric"],
    title: "Monsoon laundry: why clothes won't dry, and what we do",
    description:
      "In the monsoon, damp air and little airflow keep clothes wet for hours and leave a musty smell. Why it happens, what helps at home, and how IronDost handles laundry.",
    published: "2026-11-20",
    updated: "2026-11-20",
    answer:
      "Clothes dry when water in the fabric evaporates into the air. In the monsoon the air is already full of moisture, so evaporation is slow, and indoors there is little airflow to carry it away. Clothes that stay damp for hours start to smell musty. With IronDost, your laundry is washed in our own machines and the owner checks every load by hand before it is ironed, folded and packed.",
    sections: [
      {
        heading: "Why clothes stay wet",
        bullets: [
          "Humid air: when the air already holds a lot of moisture, it takes up water from wet clothes slowly.",
          "No sun and no breeze: clothes hung indoors or on a covered balcony get little moving air.",
          "Thick fabrics: jeans, towels and bedsheets hold more water and take the longest.",
          "Crowded racks: clothes touching each other trap damp air between them.",
        ],
      },
      {
        heading: "Why damp clothes smell",
        paragraphs: [
          "The musty smell comes from mould and bacteria that grow on fabric that stays damp too long. Once it sets in, it can come back each time the clothes get warm or a little damp again, so it is easier to prevent than to remove.",
        ],
      },
      {
        heading: "What helps at home",
        bullets: [
          "Run an extra spin so less water is left in the clothes.",
          "Space clothes out on the rack, with a gap between each piece.",
          "Use a fan, and keep a window open if the air outside is drier.",
          "Hang thick items like jeans and towels on their own, where the air moves most.",
          "Never fold or store clothes that still feel cool or damp.",
        ],
      },
      {
        heading: "What we do",
        paragraphs: [
          "Your laundry is washed in IronDost's own machines, not sent out. The owner checks every load by hand before it is ironed or folded, and nothing goes into a bag until it has passed that check.",
        ],
      },
    ],
    faq: [
      {
        q: "Does ironing help damp clothes?",
        a: "It drives out a little moisture, but ironing clothes that are still damp can set creases and trap the smell. Clothes should be dry before they are pressed.",
      },
    ],
  },
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
      "IronDost picks up within 6 km of LB Nagar Circle, Hyderabad. See the 14 localities and 7 PIN codes we serve, and what to do if you live just outside.",
    published: "2026-11-19",
    updated: "2026-11-19",
    answer: `IronDost picks up and delivers within 6 km of LB Nagar Circle in Hyderabad, in seven PIN codes: 500074, 500060, 500035, 500068, 500070, 500079 and 500059. That covers ${areas}.`,
    sections: [
      {
        heading: "Localities by PIN code",
        bullets: [
          "500074: LB Nagar",
          "500060: Dilsukhnagar, Chaitanyapuri",
          "500035: Saroornagar, Kothapet, HUDA Complex",
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
      `No iron in your PG? IronDost irons shirts from ₹${shirtNow} a piece, picked up from PGs and hostels around Dilsukhnagar and LB Nagar, with no minimum order.`,
    published: "2026-11-19",
    updated: "2026-11-19",
    answer:
      "If you live in a PG or hostel around Dilsukhnagar or LB Nagar, you can book ironing pickup from your door in the IronDost app, pay per piece, and get your clothes back pressed, usually the next day. There is no minimum number of clothes.",
    sections: [
      {
        heading: "Why it works for a PG",
        bullets: [
          `Shirt ironing is ${shirtLine} a piece, so five shirts come to ₹${shirtNow * 5}. Every price is shown before you confirm.`,
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

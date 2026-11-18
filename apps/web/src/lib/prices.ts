/**
 * The rate card, copied from the live catalogue (GET /v1/catalog on the production API) on 19 November 2026.
 * The app is the source of truth. When a price changes in the admin, update this file and `pricesUpdated` the same day.
 * Amounts are whole rupees. `offer` is the current offer price, shown with the regular price struck through.
 */
export type PriceItem = { name: string; unit: string; price: number; offer: number | null };
export type PriceCategory = { name: string; slug: string; items: PriceItem[] };

export const pricesUpdated = "2026-11-19";

export const priceList: PriceCategory[] = [
  {
    "name": "Ironing",
    "slug": "ironing",
    "items": [
      {
        "name": "Shirt / T-shirt",
        "unit": "PIECE",
        "price": 20,
        "offer": 15
      },
      {
        "name": "Trousers / Jeans",
        "unit": "PIECE",
        "price": 15,
        "offer": null
      },
      {
        "name": "Kurta",
        "unit": "PIECE",
        "price": 20,
        "offer": null
      },
      {
        "name": "Saree",
        "unit": "PIECE",
        "price": 50,
        "offer": null
      },
      {
        "name": "Dupatta",
        "unit": "PIECE",
        "price": 10,
        "offer": null
      },
      {
        "name": "Bedsheet (single)",
        "unit": "PIECE",
        "price": 25,
        "offer": null
      }
    ]
  },
  {
    "name": "Wash & Iron",
    "slug": "wash-and-iron",
    "items": [
      {
        "name": "Shirt / T-shirt",
        "unit": "PIECE",
        "price": 35,
        "offer": null
      },
      {
        "name": "Trousers / Jeans",
        "unit": "PIECE",
        "price": 40,
        "offer": null
      },
      {
        "name": "Bedsheet (double)",
        "unit": "PIECE",
        "price": 70,
        "offer": null
      }
    ]
  },
  {
    "name": "Dry Cleaning",
    "slug": "dry-cleaning",
    "items": [
      {
        "name": "Suit (2 piece)",
        "unit": "PIECE",
        "price": 350,
        "offer": null
      },
      {
        "name": "Blazer",
        "unit": "PIECE",
        "price": 200,
        "offer": null
      },
      {
        "name": "Silk saree",
        "unit": "PIECE",
        "price": 250,
        "offer": null
      }
    ]
  }
];

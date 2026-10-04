# Campaign artwork and local admin configuration

Final artwork: [Dasara](dasara-2026.png), [Diwali](diwali-2026.png), [new customers: Wash & iron](new-customer-wash-and-iron.png). Browse [the campaign board](index.html). Assets were generated separately with the built-in `image_gen.imagegen` tool; [all final prompts](prompts.json) are preserved.

Dasara: **15% off**, ₹100 minimum order, ₹100 maximum discount, **10–22 October 2026**. Diwali: **10% off**, same limits, **29 October–10 November 2026**. India time; start at 00:00 on the first date and end at 23:59:59.999 on the last. The dates follow the requested minus-10/plus-2-day rule using the [IIRS government calendar](https://www.iirs.gov.in/holidaycalender).

Both campaigns are created in local admin **Promotions** with image uploads, codes `DASARA15`/`DIWALI10` and validity windows. Customer Home reads artwork from the active-promotions API. Future promotions remain absent from the public active endpoint; the backend handles activation/expiry when content is refreshed. Do not duplicate these images as timeless active **Banners**, because standalone banners have no date fields. [Manifest](manifest.json) records exact payloads, uploaded URLs and IDs. These are local configuration changes, not production deployment.

The new-customer image says **Wash & iron for 2 shirts + 2 pants FREE on your first order**. It is uploaded to local admin **Banners** as an inactive draft. Current coupons support percentage/flat discounts and per-customer use limits, which do not implement free selected garments or true first-order eligibility. Add server-side free-item eligibility and checkout pricing before activation. The confirmed service, final image upload and inactive admin payload are recorded in the manifest. No unsupported offer has been published.

Three transparent 3D service assets are installed at `apps/customer/assets/services/ironing-3d.png`, `wash-and-iron-3d.png` and `dry-cleaning-3d.png`. Admin category images can override these; failures/loading use the bundled fallback. The image-generation prompts for these assets are in the same prompt set.

The previous local “Diwail 50%” banner used a logo board and conflicted with the requested 10% campaign. Its record and image were preserved, and its active flag was disabled.

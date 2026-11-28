/** The service area: within 6 km of LB Nagar Circle, in these PIN codes. Used by the home page, /laundry, /get and /laundry/<area>. */
export const localities = [
  { pin: "500074", names: ["LB Nagar"] },
  { pin: "500060", names: ["Dilsukhnagar", "Chaitanyapuri"] },
  { pin: "500035", names: ["Saroornagar", "Kothapet", "HUDA Complex"] },
  { pin: "500068", names: ["Mansoorabad", "Nagole", "Bandlaguda"] },
  { pin: "500070", names: ["Vanasthalipuram"] },
  { pin: "500079", names: ["Karmanghat", "Champapet"] },
  { pin: "500059", names: ["Santosh Nagar", "Saidabad"] },
];

export const slugify = (name: string) =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

/** One landing page per locality name, at /laundry/<slug>. */
export type AreaPage = { slug: string; name: string; pin: string; samePin: string[] };

export const areaPages: AreaPage[] = localities.flatMap((l) =>
  l.names.map((name) => ({ slug: slugify(name), name, pin: l.pin, samePin: l.names.filter((n) => n !== name) })),
);

export const getAreaPage = (slug: string) => areaPages.find((a) => a.slug === slug);

/** Every locality name, in order, for sentences like "LB Nagar, Dilsukhnagar, …". */
export const localityNames = areaPages.map((a) => a.name);
export const pinCodes = localities.map((l) => l.pin);

/** schema.org areaServed: every locality as a Place, plus the 6 km circle around LB Nagar Circle. */
export const placeFor = (name: string, pin: string) => ({
  "@type": "Place",
  name: `${name}, Hyderabad`,
  address: { "@type": "PostalAddress", postalCode: pin, addressLocality: "Hyderabad", addressRegion: "Telangana", addressCountry: "IN" },
});

export const areaServed = [
  ...areaPages.map((a) => placeFor(a.name, a.pin)),
  {
    "@type": "GeoCircle",
    geoMidpoint: { "@type": "GeoCoordinates", latitude: 17.3457, longitude: 78.5522 },
    geoRadius: "6000",
  },
];

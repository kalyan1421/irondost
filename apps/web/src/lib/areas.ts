/** The service area: within 6 km of LB Nagar Circle, in these PIN codes. Used by the home page and /laundry. */
export const localities = [
  { pin: "500074", names: ["LB Nagar"] },
  { pin: "500060", names: ["Dilsukhnagar", "Chaitanyapuri"] },
  { pin: "500035", names: ["Saroornagar", "HUDA Complex"] },
  { pin: "500068", names: ["Mansoorabad", "Nagole", "Bandlaguda"] },
  { pin: "500070", names: ["Vanasthalipuram"] },
  { pin: "500079", names: ["Karmanghat", "Champapet"] },
  { pin: "500059", names: ["Santosh Nagar", "Saidabad"] },
];

/** schema.org areaServed: every locality as a Place, plus the 6 km circle around LB Nagar Circle. */
export const areaServed = [
  ...localities.flatMap((l) =>
    l.names.map((name) => ({
      "@type": "Place",
      name: `${name}, Hyderabad`,
      address: { "@type": "PostalAddress", postalCode: l.pin, addressLocality: "Hyderabad", addressRegion: "Telangana", addressCountry: "IN" },
    })),
  ),
  {
    "@type": "GeoCircle",
    geoMidpoint: { "@type": "GeoCoordinates", latitude: 17.3457, longitude: 78.5522 },
    geoRadius: "6000",
  },
];

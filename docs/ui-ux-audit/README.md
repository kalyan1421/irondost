# Customer UI/UX audit and implementation

Scope: IronDost Flutter customer app only. The approved UI pass is implemented locally.

Open [implemented.html](implemented.html) for actual before-and-after captures of all 47 representative views, in both themes. [index.html](index.html) retains the original six interactive concepts for reference.

Serve this folder from the repository root:

```sh
python3 -m http.server 8765 --bind 127.0.0.1 --directory docs/ui-ux-audit
```

- [Implementation and verification](IMPLEMENTATION.md)
- [Original audit and approved phases](AUDIT.md)
- [Supplemental lifecycle and keyboard review](states.html): 12 loading/empty/offline states and seven forms, including large-text keyboard layouts.
- [Installed design system](DESIGN_SYSTEM.md)
- [Final existing-logo selection](logo/manifest.json)
- Customer token master: `packages/design-tokens/customer.tokens.json`
- Original captures: `screens/`; implemented captures: `after/`; logs: `verification/`.

The 94 captures in each set render actual application widgets using fake repositories at 390 × 844 dp. Native screenshots show local API data, safe areas and navigation. Fixture data differs from native data. Android builds and launches locally; its visual walkthrough, provider SDKs and native device accessibility require the release checks in the implementation report.

- [Final campaign artwork and local schedule](campaigns/index.html): Dasara, Diwali and new-customer banner assets; [configuration manifest](campaigns/manifest.json) and [built-in image-generation prompts](campaigns/prompts.json).

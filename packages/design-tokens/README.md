# IronDost design tokens

`tokens.json` is the design system's token file, copied from the published
[IronDost design system](https://claude.ai/artifact/3TxmJdVqHnomwZHFxMu9bR):
colours (light and dark), type styles, spacing, radii, sizes and shadows.

When the design system changes, replace `tokens.json` with its new
`project/tokens.json` and regenerate each app's code from it:

- Flutter customer app: `dart run tool/gen_tokens.dart` in `apps/customer`
  (writes `lib/design/tokens.g.dart`).

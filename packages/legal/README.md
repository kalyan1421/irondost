# @laundry/legal

The text of IronDost's Terms of service, Privacy policy and Cancellation and refunds, in one file: `legal.json`.
It was drafted from the old Cloud Ironing Factory app's policies and **needs review by whoever is responsible for the
business before release** (company name, governing law and courts, refund timelines, what is collected).

Two places read it, so edit only the JSON:

- the customer app: run `dart run tool/gen_legal.dart` in `apps/customer` (writes `lib/features/account/legal_data.g.dart`);
- the website (`apps/web`): imports the JSON directly.

Change `updated` when the text changes in a way customers should know about.

## Shape

```json
{
  "company": "…", "updated": "October 2026",
  "documents": {
    "terms": { "menuLabel": "…", "title": "…", "sections": [ { "heading": "1. …", "paragraphs": ["…"], "bullets": ["…"] } ] }
  }
}
```

`paragraphs` and `bullets` are optional, plain text, no markup.

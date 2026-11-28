# Snackbar

Short confirmation at the bottom of the screen, above the bottom nav or cart bar.

## Consumer provides
- `message` (one line, ≤ 60 characters), optional `action` ("Undo", "Retry").

## Behaviour
- `surface-inverse` with `text-inverse`; the action in `inverse-accent`. Radius `radius-md`, `shadow-raised`.
- Auto-dismiss after 4s (7s with an action). Never steals focus; announced politely.
- Errors that need a decision use a dialog or inline message instead.

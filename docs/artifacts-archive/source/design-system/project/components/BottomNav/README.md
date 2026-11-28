# BottomNav

The four top-level destinations: Home, Orders, Offers, Account.

## Behaviour
- Height `bottom-nav` (64) plus the safe area. Icons `icon-lg` with a label in `caption`/600 always visible.
- Active: icon in a 56×32 `primary-soft` pill, label in `text`. Inactive: `text-muted`.
- Re-tapping the active tab scrolls to top. Each tab keeps its own navigation stack (go_router `StatefulShellRoute`).
- Orders shows a small count badge while an order is active.

## Flutter
Material 3 `NavigationBar` themed with `indicatorColor: primary-soft`; on iOS the same widget (not a Cupertino tab bar) so both platforms match.

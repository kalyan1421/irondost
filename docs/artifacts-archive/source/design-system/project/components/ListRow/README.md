# ListRow

A settings-style row inside a grouped list: icon, label, optional value, chevron.

## Consumer provides
- `icon`, `label`, optional `value` ("English"), `onTap`, `destructive`.

## Layout
- Min height 56, padding 16, icon `icon-md` in `text-muted`, label in `body-lg`/500. Rows sit in an `id-list` group (`radius-lg`), separated by 1px `border`.
- Destructive rows ("Delete account") use `danger` for icon and label, live in their own group at the bottom, and always open a confirmation sheet.

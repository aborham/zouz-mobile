# Customer Mobile — Itemized Package Redemption

- [x] Fetch current package details and item balances
- [x] Display itemized balances in purchase list and details
- [x] Select one or more items and quantities within remaining balances
- [x] Create a short-lived server-side redemption intent
- [x] Render only server-provided opaque `qrData`
- [x] Remove permanent raw package/order-item QR generation
- [x] Show QR expiry countdown
- [x] Cancel and refresh redemption intents
- [x] Display item-level redemption history
- [x] Add English and Arabic translations
- [x] Run `dart format`
- [!] `flutter analyze`: blocked by pre-existing ignored `lib/core/config/secrets.dart`
- [!] `flutter test`: project has no `test/` directory
- [ ] Manual authenticated device test against the migrated backend

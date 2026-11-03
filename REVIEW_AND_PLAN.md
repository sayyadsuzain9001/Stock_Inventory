# NET4207 Stock Inventory Lab Test: Review and Plan (30 marks, 90 min)

Project folder: `E:\Cross-Platform-Lab-Test\stock_inventory_lab`

## 1. What the brief really asks for
A Flutter app with two screens (or one screen with two tabs):
1. **Add Item form** that writes to Firestore collection `stockItems`.
2. **Inventory screen** that reads `stockItems` live and has search, category filter, low-stock filter, quantity sort and Clear Filters.
3. **README.md** plus 3+ screenshots and a 3-row test log, pushed to GitHub.

The lecturer gives a starter project with Firebase already initialised. We do **not** run `flutterfire configure`. We only add code to `lib/` and keep their `firebase_options.dart`.

## 2. Firestore schema (must match exactly)
| Field | Dart type sent | Rule |
|---|---|---|
| sku | String | `^STK-\d{3}$` (trim, uppercase) |
| itemName | String | trimmed, length >= 3 |
| category | String | Electronics, Stationery, Hardware, Grocery |
| quantity | int | `int.tryParse`, >= 0 (rejects 4.5, -1, "abc") |
| unitPrice | double | `double.tryParse`, > 0 |
| reorderLevel | int | `int.tryParse`, >= 0 |
| createdAt | Timestamp | `FieldValue.serverTimestamp()` |

Watch-outs:
- On **Flutter Web**, 35.0 can be stored as an integer value. Read back with `(data['unitPrice'] as num).toDouble()` so it never crashes, and say so in the README.
- Document ID is auto: use `collection('stockItems').add(...)`, never `.doc('STK-101')`.

## 3. Marks map: what earns each point
### Task 1 Form (10)
| Pts | How we earn it |
|---|---|
| 3 | 6 inputs: 5 `TextFormField` + `DropdownButtonFormField<String>` for category, inside `SingleChildScrollView` + `Form` |
| 2 | `GlobalKey<FormState>`; `if (!_formKey.currentState!.validate()) return;` before any Firestore call; button disabled while saving |
| 1 | SKU message "SKU must be STK- followed by 3 digits (e.g. STK-101)"; name message "Item name must be at least 3 characters" |
| 1 | Category validator "Please choose a category" (no default selection) |
| 1 | Quantity / reorder: "Enter a whole number (0 or more)" |
| 1 | Price: "Enter a price greater than 0" (covers empty, 0, negative, text) |
| 1 | `autovalidateMode: onUserInteraction` after first submit so errors show inline under each field |

### Task 2 Firebase (7)
| Pts | How we earn it |
|---|---|
| 3 | `add()` to `stockItems`, typed fields, `createdAt` server timestamp, `await` the write |
| 2 | Invalid form never reaches `add()`; spinner on the button while saving; green SnackBar only **after** `await` returns; red SnackBar on `catch` and **form is not cleared** |
| 2 | Inventory uses `StreamBuilder` on `stockItems.orderBy('createdAt', descending: true).snapshots()`, so data survives reload. Card shows SKU, name, category, qty, price (RM x.xx), reorder |

### Task 3 Search (8)
Filtering is done in Dart on the fresh snapshot (the brief allows this and it avoids composite indexes).
| Pts | How we earn it |
|---|---|
| 2 | `kw = text.trim().toLowerCase()`; match `itemName.toLowerCase().contains(kw) \|\| sku.toLowerCase().contains(kw)` |
| 1 | Category chips/dropdown: All, Electronics, Stationery, Hardware, Grocery |
| 2 | Low-stock switch: `quantity <= reorderLevel` (badge on low items too) |
| 1 | All three applied with AND in one `where` chain |
| 1 | Sort toggle: quantity ascending / descending |
| 1 | Clear Filters button resets text, category, switch, sort; message "No items match your filters" with a Clear button |

### Task 4 README (3)
1. Setup, run commands, packages (`firebase_core`, `cloud_firestore`, plus any UI package), Firebase project ID from lecturer. No keys.
2. Schema table, validation rules, how search/low-stock/sort work.
3. Test log table (input, expected, actual) referencing `docs/screenshots/*.png`.

### Task 5 UX (2)
1. Loading spinner, empty state ("No stock items yet"), error state (`snapshot.hasError` message), readable cards.
2. Demo order: invalid submit, valid save of STK-101..103, "mouse"+Electronics+Low stock, low-stock alone, Clear.

## 4. Acceptance data and expected results (checked by hand)
| SKU | Name | Cat | Qty | Price | Reorder | Low? |
|---|---|---|---|---|---|---|
| STK-101 | USB C Cable | Electronics | 4 | 19.90 | 5 | yes (4<=5) |
| STK-102 | Notebook | Stationery | 25 | 4.50 | 10 | no |
| STK-103 | Wireless Mouse | Electronics | 1 | 35.00 | 3 | yes (1<=3) |

- "mouse" + Electronics + Low stock gives only STK-103. Correct.
- "STK-102" + All gives Notebook; typing "stk-10" in lower case must also work.
- Sort qty ascending gives 103 (1), 101 (4), 102 (25). Correct.
- Low stock alone gives **two** items (101 and 103). Good to show in the demo.
- Clear restores all three.

## 5. Code layout (small, quick to build)
```
lib/
  main.dart                 // keep starter's Firebase.initializeApp; theme; HomeShell with 2 tabs
  models/stock_item.dart    // fromDoc / toMap, num->double safe
  utils/validators.dart     // pure functions, easy to unit test
  screens/add_item_screen.dart
  screens/inventory_screen.dart
test/validators_test.dart   // proves every rule (bonus evidence)
README.md
docs/screenshots/01_invalid.png 02_saved.png 03_inventory.png 04_combined.png 05_low_stock.png 06_sort.png
```

## 6. Look and feel (your preferences, kept light so they never cost marks)
- Premium palette: midnight `#0E1330` app bar, indigo `#2B2F77`, gold accent `#D4A24C`, canvas `#F5F6FA`, red for low stock.
- Gradient header with an online warehouse image (`Image.network` with `errorBuilder` fallback so a blocked image never breaks the app).
- Click animations: scale-on-press Save button, animated success tick, `AnimatedSwitcher` on the list, cards fade/slide in.
- Material 3, category icons and colour-coded chips, stock badge (Low / OK).

## 7. 90-minute timeline
| Min | Work |
|---|---|
| 0-5 | Open starter, `flutter pub get`, run once to confirm Firestore works |
| 5-30 | Model, validators, Add Item form (Task 1) |
| 30-45 | Save with progress/success/error (Task 2 write) |
| 45-65 | Inventory StreamBuilder, filters, sort, clear, states (Task 2 read, 3, 5) |
| 65-75 | Enter test data, run all 6 acceptance tests, take screenshots |
| 75-85 | README + test log |
| 85-90 | `git add . && git commit && git push`, check repo on GitHub, submit URL |

## 8. Risks
- **Flutter is not available from my side.** Building, running and screenshots need your PC, via a Remote Control session in this folder.
- Do not commit `google-services.json` or service-account files if the lecturer says not to. Check `.gitignore`. (`firebase_options.dart` holds public client config only.)
- If Firestore rules reject writes, the red error SnackBar is our evidence; note it in the README under the disruption policy.

## 9. Skills
No special skill is needed. I can write all of this directly. Afterwards `code-review` can check the code for bugs and `run` can launch the app, both on your PC through Remote Control.

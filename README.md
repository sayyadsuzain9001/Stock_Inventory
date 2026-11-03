# Stock Inventory Manager (NET4207 Lab Test)

A Flutter app for a small retailer. It saves stock items to **Cloud Firestore**, lists them live and supports advanced search. It has a dashboard, an add-item form and an inventory view.

## Setup and run
- **Firebase project ID:** `stockinvetory` (Web app config in `lib/firebase_options.dart`. These are public client IDs, and no keys or service accounts are committed.)
- **Packages:** `firebase_core`, `cloud_firestore`, `google_fonts`, `flutter_animate`. Dev: `fake_cloud_firestore`.

```bash
flutter pub get
flutter run -d chrome          # or: flutter run -d edge / windows
flutter test                   # 18 unit + widget tests
```
Firestore rules are in `firestore.rules`. Paste them into the console under Firestore > Rules.

## `stockItems` schema (auto document ID)
| Field | Type | Rule |
|---|---|---|
| sku | String | `STK-` + 3 digits |
| itemName | String | trimmed, at least 3 characters |
| category | String | Electronics, Stationery, Hardware or Grocery |
| quantity | Integer | whole number, 0 or more |
| unitPrice | Number | RM greater than 0 (at most 2 decimals) |
| reorderLevel | Integer | whole number, 0 or more |
| createdAt | Timestamp | `FieldValue.serverTimestamp()` |

## How it works
**Validation.** The `Form` uses a `GlobalKey<FormState>`. `validate()` must pass before `add()` is called, so invalid input never reaches Firestore, and each field shows its own error. While saving, the Save button shows a spinner. The success dialog and SnackBar appear only after Firestore acknowledges the write. If the write fails, a red SnackBar appears and the form keeps what you typed.

**Retrieval.** A `StreamBuilder` listens to `stockItems` ordered by `createdAt`, so data is reloaded from Firestore every time the app opens. The app shows a loading skeleton while data loads, a message when the list is empty or nothing matches, and an error message with a Retry button if loading fails.

**Advanced search.** Filtering and sorting run in Flutter on the fresh Firestore snapshot. Active controls are combined with **AND**:
- The keyword is a lower-case `contains` match on `itemName` **or** `sku`.
- The category filter is `All` or one of the four categories.
- **Low stock only** keeps items where `quantity <= reorderLevel`.
- **Sort** orders by quantity, ascending or descending. **Clear Filters** resets every control.

**Submitted records.** Every record card shows **when it was submitted**, which is its `createdAt` server timestamp shown in local time. Saved items appear at the top of the list right away. The **Submitted** filter offers All time, Today, Last 7 days, or **Pick dates…**, which opens a date-range picker. The sort menu orders records by Newest first, Oldest first, or Quantity (low to high, or high to low). The date filter is combined with all the other filters using AND.

Note: Flutter Web stores a price such as `35.00` as an integer, so the app reads prices back as `num`.

## Test log (live Firestore project `stockinvetory`)
| # | Input | Expected | Actual | Evidence |
|---|---|---|---|---|
| 1 | Blank form, then `STK1`, `ab`, qty `-1`, reorder `2.5`, price `0` | Inline errors and no document written | Six specific errors shown and the collection still had 0 documents | `02_invalid_blank.png`, `03_invalid_malformed.png` |
| 2 | Save STK-101, STK-102, STK-103 | Three retrievable records with the correct values | Saving spinner, then a confirmation with the doc ID. Three typed documents with `createdAt`, all listed again after a reload | `04_saving_progress.png`, `05_saved_dialog.png`, `06_inventory_all.png`, `firestore_documents.json` |
| 3 | Search `mouse` + Electronics + Low stock | Only STK-103 | Only STK-103 (Showing 1 of 4) | `07_combined_search.png` |
| 4 | Search `STK-102` with All | Notebook | Notebook only | `09_sku_search.png` |
| 5 | Low stock only | STK-101 and STK-103 | STK-103 and STK-101 | `10_low_stock.png` |
| 6 | Sort quantity ascending | STK-103, STK-101, then STK-102 | 103 (1), 101 (4), 104 (12), 102 (25) | `11_sort_ascending.png` |
| 7 | Clear Filters after a combined search | Full list | Showing 4 of 4 | `08_cleared.png` |
| 8 | Inventory after saving, with Today filter and Oldest first | Every record shows its submitted date and time and can be filtered by date | 4 of 4 records shown, each with a timestamp. Oldest first gives 101, 102, 103, 104 | `17_records_with_timestamps.png`, `18_filter_today.png`, `19_sort_menu.png`, `20_sort_oldest.png`, `21_pick_dates.png` |

STK-104 (Claw Hammer, Hardware) is an extra realistic item, which the brief allows. Screenshots are in `docs/screenshots/`, and `14`–`16` show the phone layout.

## Live demo
https://sayyadsuzain9001.github.io/Stock_Inventory/ (deployed automatically by `.github/workflows/deploy-pages.yml` on every push to `main`).

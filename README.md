# Jewelry ERP: Data Tables Demo

A small Flutter desktop and web demo for a jewelry store ERP. It shows what
"Excel-style" screens look like when they are built as normal business tables
instead of a spreadsheet:

- tables that sort, filter and search
- totals that follow the filters
- export of the current view to a real Excel file
- import of an Excel file with a preview and validation step

There is no backend, database or login. All data is generated in memory at
startup from a fixed random seed (`Random(42)`), so it looks the same on every
run. Nothing is saved between runs.

## How to run

You need Flutter (stable) installed.

```
flutter pub get
flutter run -d windows     # Windows desktop
flutter run -d chrome      # Browser
```

The window should be at least 1200 px wide. Narrower windows scroll sideways.

Checks:

```
flutter analyze
flutter test
```

## Demo script (about 2 minutes)

Start on the **Stock** screen.

1. Point at the bottom bar: "Showing 600 of 600 articles" with total weight
   and total value. These numbers always describe what is in the table.
2. Click the **Gold** chip. The table and the totals change at once.
3. Type `ring` in the search box. Now it is gold rings only.
4. Click the small filter icon in the **Gross Wt (g)** header, open
   **Number Filters**, choose **Less Than**, type `5` and press OK. The table
   now shows gold rings under 5 grams. Watch the totals bar change again.
5. Click the **Tag Price** header to sort, click again to reverse it.
6. Scroll the table sideways: the Article Code column stays in place.
7. Click any row. The details panel opens on the right. Press **Edit**, change
   the tag price, press Save. The row and the totals update.
8. Press **Export to Excel** and save the file. Open it in Excel: only the
   filtered rows are there, the header row is frozen, numbers are real numbers
   (select a price column and Excel shows the sum), and the last row holds the
   same totals as the app.
9. Press **Clear filters** to get all 600 articles back.

Then go to **Import from Excel**.

10. Press **Load sample file (200 rows)**. (Or press **Choose Excel file** and
    pick `assets/sample_import.xlsx`, or drag that file onto the drop area.)
11. Read the summary line: "188 ready to import, 4 warnings, 8 errors".
    Scroll a little: error rows are red, warning rows are yellow, and the
    Issues column says what is wrong in plain words.
12. Press **Errors only** to see just the 8 failed rows. Press
    **Download error rows** to get them as an Excel file that can be fixed and
    imported again.
13. Press **Continue**, then **Import 189 articles**, then **View in Stock**.
    The Stock screen opens showing only the articles added today.

If there is time, open **Sales Report**: press **Last 7 days** and watch the
four cards change, then set **Group by** to **Salesman** and click a name to
expand that salesman's sales.

## What is in each screen

**Stock.** Search box, category chips, status (multi-select), branch and date
filters, a Columns menu to show or hide columns, sorting on every header, an
Excel-style filter popup on every header, column resize and drag to reorder, a
frozen first column, paging (25 / 50 / 100 rows), a totals bar, a read-only
details panel and an Edit form dialog. Cells are never edited in the table.

**Sales Report.** Date presets and range, salesman / branch / payment /
category filters, four summary cards, the same table behaviour as Stock, and a
Group by switch (Salesman, Category, Day) that shows one expandable row per
group with its totals.

**Import from Excel.** Three steps: choose file, preview and validate, confirm.
Headers are matched without regard to capital letters or extra spaces, and
unknown columns are ignored.

**Export.** Exports what is on screen: current filters, current sort order and
only the visible columns, all matching rows rather than just the current page.
Money and weights are numeric cells, dates are date cells. A grouped sales
report puts the group summary on sheet 1 and the detailed rows on sheet 2.

## Notes for developers

Structure:

```
lib/
  main.dart
  app.dart                 theme, navigation rail shell
  models/                  article.dart, sale.dart, enums.dart
  data/
    seed_data.dart         deterministic generator
    app_store.dart         ChangeNotifier: data + toolbar filters
  features/
    stock/                 screen, toolbar, table, details panel, edit dialog
    sales_report/          screen, summary cards, table, grouped view
    import/                stepper screen, parser, validator, template files
  shared/
    excel_export.dart      the one export function
    grid_columns.dart      column definitions, layout, base grid data source
    formatters.dart        money, weight, date, percent
    widgets/               data grid wrapper, totals bar, status pill, filters
tool/
  generate_sample_import.dart   rebuilds assets/sample_import.xlsx
```

- Money is stored as whole rupees (`int`) and weight as milligrams (`int`).
  Formatting happens only at display and export time.
- Toolbar filters are applied in `AppStore`. The grid's own header filters
  apply on top. The totals bar, the summary cards, the grouped view and the
  export all read the rows left after both, from the grid source's effective
  rows.
- The grid is Syncfusion `SfDataGrid` with `SfDataPager`, used under the
  Syncfusion Community License. Excel files are written with
  `syncfusion_flutter_xlsio` and read with `excel`.
- **Package versions.** The Syncfusion packages are held at 29.2.11 although
  newer ones exist. From version 30 they need `archive` 4, and the `excel`
  package (latest 4.0.6) only works with `archive` 3, so the two cannot be
  combined at their newest versions. 29.2.11 is the newest Syncfusion release
  that resolves together with `excel`.
- **Grouping.** The grid's built-in grouping only groups the rows of the
  current page when a pager is attached, which would make the group totals
  wrong. The grouped Sales Report is therefore a separate summary table fed
  from the same filtered and sorted rows.
- **Seed data.** 250 sales each need their own Sold article, so 250 of the 600
  articles are Sold, 300 are Available and 50 are spread over the other
  statuses.
- To regenerate the sample import file:
  `dart run tool/generate_sample_import.dart`

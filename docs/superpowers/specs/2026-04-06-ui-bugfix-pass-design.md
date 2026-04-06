# UI Bugfix Pass Design

## Goal

Fix the current UI interaction bugs in the macOS extension-association manager without changing the underlying Launch Services read/write architecture.

## Scope

### In Scope

- Auto-select the first visible extension row after the first successful load.
- Make the single-extension app picker dismissible without forcing a selection.
- Show the default app icon in the table's `Default App` column.
- In the single-extension app picker, show the selected row's candidate apps before other apps.

### Out of Scope

- Status filters or new toolbar controls.
- Batch picker prioritization changes.
- Candidate-app discovery accuracy improvements.
- Performance work such as icon caching.
- Any change to Launch Services persistence behavior.

## Bugs to Fix

### 1. Initial layout collapses into the lower-left area

Current behavior suggests the UI enters its loaded state with no selected row, which leaves the sidebar in an empty-state configuration and causes the split view to feel visually collapsed or misplaced.

The fix is to auto-select the first visible row once, immediately after the first successful data load.

Rules:

- Only run this auto-selection after the initial successful load.
- Do not re-select automatically during later refreshes if the user has already made a choice.
- Do not change selection as a side effect of search filtering in this pass.

### 2. Single-item app picker cannot be manually closed

Current behavior only supports dismissal through choosing an app.

The fix is to add explicit dismissal affordances:

- a visible `Cancel` button inside the sheet
- normal sheet-window close behavior

Closing the sheet must not trigger any write operation.

### 3. Table does not show the default app icon

The `Default App` column should render:

- app icon
- app display name

If no default app exists, render `Not Set` as plain text without a placeholder icon.

The icon should be small and aligned so table row height stays stable.

### 4. Single-item picker should prioritize candidate apps

When changing the default app for one selected extension, the picker should present the current row's candidate apps before all other installed apps.

This should be presented as grouped UI, not just loose sorting:

- `Candidate Apps`
- `Other Apps`

Rules:

- `Candidate Apps` contains only the selected row's `candidateApps`.
- `Other Apps` contains all remaining available apps not already present in `Candidate Apps`.
- Search applies before display, but grouping order remains candidate-first.
- If the row has no candidate apps, do not show an empty candidate section.
- This grouping applies only to the single-extension picker.
- The batch picker remains unchanged in this pass.

## UX Design

## Root View Selection Behavior

After the first successful load:

1. If `selection` is empty
2. and there is at least one visible row
3. select the first row's `normalizedExtension`

This should be implemented as a one-time behavior tied to initial load completion, not as a general selection policy.

## Table Column Rendering

The `Default App` column becomes a compact horizontal layout:

- icon
- app name

For missing values:

- show `Not Set`
- use secondary styling

The existing candidate-count and status columns remain unchanged.

## Single-Item App Picker

The sheet receives explicit single-row context:

- selected extension label
- candidate apps for that extension
- full installed app list

Display behavior:

- search field at top
- grouped list below
- `Cancel` action at bottom

The sheet should still allow immediate app selection from either section.

## Architecture Changes

These fixes stay in the UI and view-model boundary.

### RootView

Responsibilities added:

- detect first successful load completion
- trigger one-time default selection
- pass single-row context into the single-item picker

### AppPickerSheet

Responsibilities added:

- support optional single-item context
- render grouped sections for candidate apps and other apps
- expose explicit cancel dismissal

### AssociationTableView

Responsibilities added:

- render app icons in the `Default App` column

### AssociationListViewModel

No behavior change is required for persistence or Launch Services writes. It may gain a minimal helper if needed for first-load selection, but this pass should avoid pushing UI-specific selection policy into lower layers unless necessary.

## Testing Strategy

### Automated Tests

Add or update tests for:

- first successful load selects the first row when selection is empty
- candidate apps are surfaced ahead of other apps in the single-item picker model
- cancellation path does not trigger app reassignment

### Build Verification

Verify:

- `swift test`
- `swift build`

### Manual Validation

Validate in the running app:

1. Launch app and confirm one row is selected automatically on first load.
2. Confirm the split UI appears in a stable full-window layout.
3. Open the single-item picker and dismiss it via `Cancel`.
4. Re-open the picker and verify candidate apps appear before the rest.
5. Confirm the table shows app icons in the `Default App` column.

## Acceptance Criteria

This pass is complete when:

- the first row is auto-selected after the first successful load
- the single-item picker can be dismissed without selecting an app
- the table shows app icons next to default app names
- the single-item picker groups candidate apps ahead of other apps
- batch picker behavior remains unchanged

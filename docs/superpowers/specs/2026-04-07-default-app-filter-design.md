# Default App Filter Design

## Goal

Add table filtering by current default app so users can quickly see which file extensions are currently bound to a given app.

## Scope

### In Scope

- Add a toolbar filter for `Default App`
- Allow clicking a table row's default app cell to apply that filter
- Show only rows whose current default app matches the selected filter
- Preserve a clear way to return to the unfiltered state
- Keep selection and sidebar state coherent when filters change

### Out of Scope

- Multi-app combined filters
- Candidate-app-based filtering
- Status filter combinations
- Saved filter presets
- Right-click or contextual filter actions

## Product Behavior

Users should be able to answer:

- "Which extensions are currently opened by VS Code?"
- "How many extensions are bound to Preview right now?"
- "What did this app take over as the default?"

This is a current-state filter based on `currentDefaultApp`, not a capability filter and not a candidate-app filter.

## Filtering Model

The filter is single-select.

- `All Apps` means no default-app filtering
- selecting one app means: show only rows where `row.currentDefaultApp?.bundleIdentifier` matches that app

The filter should operate on the same source rows already loaded into memory. No repository reload is required.

## Toolbar UI

Add a toolbar control labeled `Default App`.

Behavior:

- default value is `All Apps`
- options are derived from the current rows' `currentDefaultApp` values
- options are unique and sorted by app display name
- only apps that are currently acting as a default for at least one listed extension appear in the filter menu

This keeps the control focused on "apps that currently own extensions" rather than all installed apps.

## Table Interaction

The `Default App` cell becomes a filter shortcut:

- if the row has a default app, clicking the cell applies the filter for that app
- if the row has no default app, there is no click action

This interaction should write to the same filter state used by the toolbar control.

There must be one source of truth for the filter value.

## Selection Behavior

Filtering changes what is visible, so selection must stay valid.

Rules:

- if the current selection remains visible after filtering, keep it
- if the current selection is no longer visible, move selection to the first visible row
- if no rows remain visible, clear selection

This prevents the right-hand detail panel from describing a row that is no longer in the filtered table.

## Empty State

If a selected default-app filter produces zero rows, the main content should show a clear filter-specific empty state, for example:

- no rows are currently opened by this app
- use the toolbar to switch back to `All Apps`

This empty state should not look like a loading failure.

## Architecture Changes

### AssociationListViewModel

Add responsibilities for:

- storing the selected default-app filter
- exposing filter options derived from current rows
- applying the filter inside `visibleRows`
- reconciling selection when the filter changes

### RootView

Add responsibilities for:

- rendering the toolbar filter control
- showing a filter-aware empty state when `visibleRows` is empty under `.loaded`

### AssociationTableView

Add responsibilities for:

- making the default app cell clickable when a default app exists
- routing click actions back to the view model filter state

## Testing Strategy

### Automated Tests

Add or update tests for:

- filtering rows by one default app
- clearing back to `All Apps`
- keeping selection if the selected row remains visible
- moving selection to the first visible row if the current selection becomes hidden
- filter options are unique and sorted

### Build Verification

Verify:

- `swift test`
- `swift build`

### Manual Validation

Validate in the running app:

1. pick a default app from the toolbar filter and confirm only matching extensions remain
2. click a default app directly in the table and confirm the same filter is applied
3. switch back to `All Apps` and confirm the full list returns
4. confirm the sidebar tracks the visible selection correctly after filtering
5. confirm the filtered view makes it easy to see that one app owns multiple extensions

## Acceptance Criteria

This feature is complete when:

- users can filter the table by one current default app from the toolbar
- clicking a default app in the table applies that same filter
- selection stays coherent as the visible set changes
- `All Apps` restores the unfiltered list
- the filtered view clearly supports auditing "which extensions this app currently owns"

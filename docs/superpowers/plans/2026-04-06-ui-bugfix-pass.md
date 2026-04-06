# UI Bugfix Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the current UI interaction bugs around initial selection, single-item picker dismissal, table icon rendering, and candidate-first app ordering.

**Architecture:** Keep the Launch Services and repository layers unchanged. Apply a narrow UI-focused patch across the root view, the table column renderer, and the single-item picker, with tests added at the view-model and helper-model level so the new interaction logic stays deterministic.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Observation, XCTest / Testing

---

## File Structure

- Modify: `Sources/OpenWithGUIApp/ViewModels/AssociationListViewModel.swift`
- Modify: `Sources/OpenWithGUIApp/Views/RootView.swift`
- Modify: `Sources/OpenWithGUIApp/Views/AssociationTableView.swift`
- Modify: `Sources/OpenWithGUIApp/Views/AppPickerSheet.swift`
- Create: `Sources/OpenWithGUIApp/Models/AppPickerSection.swift`
- Modify: `Tests/OpenWithGUIAppTests/ViewModels/AssociationListViewModelTests.swift`
- Create: `Tests/OpenWithGUIAppTests/Models/AppPickerSectionTests.swift`

## Task 1: Add failing tests for initial selection and single-item picker grouping

**Files:**
- Modify: `Tests/OpenWithGUIAppTests/ViewModels/AssociationListViewModelTests.swift`
- Create: `Tests/OpenWithGUIAppTests/Models/AppPickerSectionTests.swift`

- [ ] **Step 1: Add the failing first-load selection test**

Update `Tests/OpenWithGUIAppTests/ViewModels/AssociationListViewModelTests.swift` with:

```swift
    @Test
    func selectsFirstRowAfterInitialLoadWhenSelectionIsEmpty() async throws {
        let textEdit = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: textEdit, candidateApps: [textEdit]),
                ExtensionAssociationRow(rawExtension: "md", currentDefaultApp: nil, candidateApps: [])
            ],
            apps: [textEdit]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))

        await viewModel.load()
        viewModel.selectFirstRowIfNeeded()

        #expect(viewModel.selection == ["json"])
    }
```

- [ ] **Step 2: Add the failing candidate-first grouping tests**

Create `Tests/OpenWithGUIAppTests/Models/AppPickerSectionTests.swift`:

```swift
import Foundation
import Testing
@testable import OpenWithGUIApp

struct AppPickerSectionTests {
    @Test
    func groupsCandidateAppsAheadOfOtherAppsWithoutDuplication() {
        let candidate = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )
        let other = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )

        let sections = AppPickerSection.makeSections(
            apps: [candidate, other],
            candidateApps: [candidate],
            searchText: ""
        )

        #expect(sections.map(\.title) == ["Candidate Apps", "Other Apps"])
        #expect(sections[0].apps == [candidate])
        #expect(sections[1].apps == [other])
    }

    @Test
    func omitsEmptyCandidateSection() {
        let app = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )

        let sections = AppPickerSection.makeSections(
            apps: [app],
            candidateApps: [],
            searchText: ""
        )

        #expect(sections.map(\.title) == ["Other Apps"])
        #expect(sections[0].apps == [app])
    }
}
```

- [ ] **Step 3: Run tests to verify they fail for the expected missing APIs**

Run:

```bash
swift test --filter AssociationListViewModelTests
swift test --filter AppPickerSectionTests
```

Expected:

- the view-model test fails because `selectFirstRowIfNeeded()` does not exist yet
- the picker-section tests fail because `AppPickerSection` does not exist yet

- [ ] **Step 4: Commit the red tests**

Run:

```bash
git add Tests/OpenWithGUIAppTests/ViewModels/AssociationListViewModelTests.swift Tests/OpenWithGUIAppTests/Models/AppPickerSectionTests.swift
git commit -m "test: cover ui bugfix pass behavior"
```

Expected: one commit containing the new failing tests.

## Task 2: Implement the selection helper and picker grouping model

**Files:**
- Modify: `Sources/OpenWithGUIApp/ViewModels/AssociationListViewModel.swift`
- Create: `Sources/OpenWithGUIApp/Models/AppPickerSection.swift`

- [ ] **Step 1: Add the one-time selection helper to the view model**

Update `Sources/OpenWithGUIApp/ViewModels/AssociationListViewModel.swift`:

```swift
    func selectFirstRowIfNeeded() {
        guard selection.isEmpty, let firstRow = visibleRows.first else {
            return
        }

        selection = [firstRow.normalizedExtension]
    }
```

- [ ] **Step 2: Implement the picker grouping model**

Create `Sources/OpenWithGUIApp/Models/AppPickerSection.swift`:

```swift
import Foundation

struct AppPickerSection: Identifiable, Equatable {
    let title: String
    let apps: [AppDescriptor]

    var id: String { title }

    static func makeSections(
        apps: [AppDescriptor],
        candidateApps: [AppDescriptor],
        searchText: String
    ) -> [AppPickerSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredApps = apps.filter { app in
            guard !query.isEmpty else { return true }
            return app.displayName.lowercased().contains(query)
                || app.bundleIdentifier.lowercased().contains(query)
        }

        let filteredCandidates = candidateApps.filter { candidate in
            filteredApps.contains(candidate)
        }

        let candidateIDs = Set(filteredCandidates.map(\.id))
        let otherApps = filteredApps.filter { !candidateIDs.contains($0.id) }

        var sections: [AppPickerSection] = []

        if !filteredCandidates.isEmpty {
            sections.append(AppPickerSection(title: "Candidate Apps", apps: filteredCandidates))
        }

        sections.append(AppPickerSection(title: "Other Apps", apps: otherApps))
        return sections.filter { !$0.apps.isEmpty }
    }
}
```

- [ ] **Step 3: Run tests to verify the new model behavior passes**

Run:

```bash
swift test --filter AssociationListViewModelTests
swift test --filter AppPickerSectionTests
```

Expected: both test groups pass.

- [ ] **Step 4: Commit the core behavior changes**

Run:

```bash
git add Sources/OpenWithGUIApp/ViewModels/AssociationListViewModel.swift Sources/OpenWithGUIApp/Models/AppPickerSection.swift Tests/OpenWithGUIAppTests/ViewModels/AssociationListViewModelTests.swift Tests/OpenWithGUIAppTests/Models/AppPickerSectionTests.swift
git commit -m "feat: add ui bugfix selection and picker models"
```

Expected: one commit containing the helper and section model.

## Task 3: Patch the views for auto-selection, cancelable single-item picker, and app icons

**Files:**
- Modify: `Sources/OpenWithGUIApp/Views/RootView.swift`
- Modify: `Sources/OpenWithGUIApp/Views/AssociationTableView.swift`
- Modify: `Sources/OpenWithGUIApp/Views/AppPickerSheet.swift`

- [ ] **Step 1: Update the root view to auto-select on first successful load**

Update `Sources/OpenWithGUIApp/Views/RootView.swift`:

```swift
    @State private var hasAppliedInitialSelection = false
```

Add this after the `.task` block in `body`:

```swift
        .onChange(of: viewModel.phase) { _, newPhase in
            guard newPhase == .loaded, !hasAppliedInitialSelection else {
                return
            }

            viewModel.selectFirstRowIfNeeded()
            hasAppliedInitialSelection = true
        }
```

- [ ] **Step 2: Pass row context into the single-item picker**

Update the single-item sheet in `Sources/OpenWithGUIApp/Views/RootView.swift`:

```swift
        .sheet(isPresented: $showingSinglePicker, onDismiss: {
            singleSelectionExtension = nil
        }) {
            let selectedRow = viewModel.rows.first { $0.normalizedExtension == singleSelectionExtension }

            AppPickerSheet(
                apps: viewModel.availableApps,
                title: "Set Default App for .\(singleSelectionExtension ?? "")",
                candidateApps: selectedRow?.candidateApps ?? [],
                showsCandidateGrouping: true,
                onSelect: { app in
                    guard let normalizedExtension = singleSelectionExtension else {
                        return
                    }

                    Task {
                        await viewModel.apply(app: app, to: [normalizedExtension])
                    }
                    singleSelectionExtension = nil
                    showingSinglePicker = false
                }
            )
        }
```

Update the batch picker call in the same file:

```swift
            AppPickerSheet(
                apps: viewModel.availableApps,
                title: "Set Selected Extensions",
                candidateApps: [],
                showsCandidateGrouping: false,
                onSelect: { app in
```

- [ ] **Step 3: Show app icons in the table column**

Update `Sources/OpenWithGUIApp/Views/AssociationTableView.swift`:

```swift
import AppKit
import SwiftUI
import Observation
```

Replace the `Default App` column with:

```swift
            TableColumn("Default App") { row in
                if let app = row.currentDefaultApp {
                    HStack(spacing: 8) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.appURL.path))
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(app.displayName)
                    }
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
            }
```

- [ ] **Step 4: Make the picker grouped and cancelable**

Update `Sources/OpenWithGUIApp/Views/AppPickerSheet.swift`:

```swift
import AppKit
import SwiftUI

struct AppPickerSheet: View {
    let apps: [AppDescriptor]
    let title: String
    let candidateApps: [AppDescriptor]
    let showsCandidateGrouping: Bool
    let onSelect: (AppDescriptor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())

            TextField("Search apps", text: $searchText)

            List {
                ForEach(sections) { section in
                    Section(section.title) {
                        ForEach(section.apps) { app in
                            Button {
                                onSelect(app)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.appURL.path))
                                        .resizable()
                                        .frame(width: 28, height: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(app.displayName)
                                        Text(app.bundleIdentifier)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(minHeight: 320)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 520, height: 480)
    }

    private var sections: [AppPickerSection] {
        if showsCandidateGrouping {
            return AppPickerSection.makeSections(
                apps: apps,
                candidateApps: candidateApps,
                searchText: searchText
            )
        }

        let filteredApps = apps.filter { app in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            return app.displayName.lowercased().contains(query)
                || app.bundleIdentifier.lowercased().contains(query)
        }

        return [AppPickerSection(title: "Apps", apps: filteredApps)]
    }
}
```

- [ ] **Step 5: Run the full verification set**

Run:

```bash
swift test
swift build
```

Expected:

- all automated tests pass
- the app still builds cleanly with the new sheet and table rendering

- [ ] **Step 6: Commit the UI fixes**

Run:

```bash
git add Sources/OpenWithGUIApp/Views Sources/OpenWithGUIApp/Models/AppPickerSection.swift Sources/OpenWithGUIApp/ViewModels/AssociationListViewModel.swift Tests
git commit -m "fix: improve ui picker and initial selection behavior"
```

Expected: one commit containing the visible UI fixes.

## Task 4: Run manual GUI verification

**Files:**
- No code changes required unless a defect is found

- [ ] **Step 1: Launch the app**

Run:

```bash
swift run OpenWithGUI
```

Expected: the app launches and remains running until manually closed.

- [ ] **Step 2: Validate the approved scenarios**

Validate manually:

```text
1. On first launch, confirm one row is selected automatically.
2. Confirm the table fills the main content area rather than collapsing into the lower-left corner.
3. Open the single-item picker and close it with Cancel.
4. Re-open the single-item picker and confirm candidate apps appear before other apps.
5. Confirm the Default App column shows app icons next to app names.
```

Expected: all five behaviors match the approved bugfix spec.

- [ ] **Step 3: Commit only if a manual-validation fix was needed**

Run only if you made an additional patch during manual validation:

```bash
git add Sources Tests
git commit -m "fix: polish ui bugfix validation findings"
```

Expected: commit exists only if manual validation revealed and fixed another defect.

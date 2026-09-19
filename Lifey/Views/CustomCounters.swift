import SwiftUI

/// Lists the table's own counters and offers a way to add another. Used on the setup
/// screen and in the mid-game menu.
struct CustomCounterSection: View {
    @EnvironmentObject private var store: GameStore
    @State private var editing: CustomCounter?
    @State private var isAdding = false

    var body: some View {
        VStack(spacing: 8) {
            ForEach(store.config.customCounters) { counter in
                Button {
                    Feedback.shared.select()
                    editing = counter
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: counter.symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(counter.tint)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(counter.tint.opacity(0.16)))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(counter.title)
                                .font(.tally(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(counter.abbreviation)
                                .font(.tally(12, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.surfaceHigh)
                    )
                }
                .buttonStyle(.plain)
            }

            SecondaryButton(title: "Add a counter", symbol: "plus", tint: Color(hex: 0x4CC9F0)) {
                isAdding = true
            }
        }
        .sheet(isPresented: $isAdding) {
            CounterEditorSheet(counter: nil) { counter in
                store.addCustomCounter(counter)
            } onDelete: {
                // A counter being created has nothing to delete.
            }
            .presentationDetents([.large])
            .presentationBackground(Theme.surface)
        }
        .sheet(item: $editing) { counter in
            CounterEditorSheet(counter: counter) { updated in
                store.updateCustomCounter(updated)
            } onDelete: {
                store.removeCustomCounter(id: counter.id)
            }
            .presentationDetents([.large])
            .presentationBackground(Theme.surface)
        }
    }
}

/// Name, short label, symbol and colour for one custom counter.
struct CounterEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let isNew: Bool
    private let onSave: (CustomCounter) -> Void
    private let onDelete: () -> Void

    @State private var draft: CustomCounter
    @State private var abbreviationEdited: Bool
    @State private var confirmDelete = false

    init(
        counter: CustomCounter?,
        onSave: @escaping (CustomCounter) -> Void,
        onDelete: @escaping () -> Void
    ) {
        isNew = counter == nil
        self.onSave = onSave
        self.onDelete = onDelete
        _draft = State(
            initialValue: counter ?? CustomCounter(
                title: "",
                abbreviation: "",
                symbol: CustomCounter.symbolChoices[0],
                colorHex: CustomCounter.colorChoices[0]
            )
        )
        _abbreviationEdited = State(initialValue: !(counter?.abbreviation ?? "").isEmpty)
    }

    private var resolvedAbbreviation: String {
        abbreviationEdited && !draft.abbreviation.isEmpty
            ? draft.abbreviation
            : CustomCounter.suggestedAbbreviation(from: draft.title)
    }

    private var canSave: Bool {
        !draft.title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header

                SectionCard(title: "Name") {
                    TextField("Monarch turns", text: $draft.title)
                        .textFieldStyle(.plain)
                        .font(.tally(20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surfaceHigh))

                    HStack(spacing: 10) {
                        Text("Chip label")
                            .font(.tally(14, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        TextField(CustomCounter.suggestedAbbreviation(from: draft.title), text: $draft.abbreviation)
                            .textFieldStyle(.plain)
                            .font(.tally(17, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: draft.abbreviation) { _, value in
                                abbreviationEdited = !value.isEmpty
                                if value.count > 4 {
                                    draft.abbreviation = String(value.prefix(4))
                                }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceHigh))
                    }
                }

                SectionCard(title: "Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(CustomCounter.symbolChoices, id: \.self) { symbol in
                            Button {
                                Feedback.shared.select()
                                draft.symbol = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(draft.symbol == symbol ? .black : Theme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(draft.symbol == symbol ? draft.tint : Theme.surfaceHigh)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SectionCard(title: "Colour") {
                    HStack(spacing: 8) {
                        ForEach(CustomCounter.colorChoices, id: \.self) { hex in
                            Button {
                                Feedback.shared.select()
                                draft.colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(height: 34)
                                    .overlay(
                                        Circle().stroke(
                                            .white.opacity(draft.colorHex == hex ? 0.95 : 0),
                                            lineWidth: 3
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SectionCard(title: "Preview", subtitle: "How it looks on a panel") {
                    HStack(spacing: 6) {
                        Image(systemName: draft.symbol)
                            .font(.system(size: 14, weight: .bold))
                        Text("0")
                            .font(.tally(18, weight: .heavy))
                        Text(resolvedAbbreviation.isEmpty ? "NEW" : resolvedAbbreviation)
                            .font(.tally(12, weight: .semibold))
                            .opacity(0.75)
                    }
                    .foregroundStyle(draft.tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.28)))
                    .overlay(Capsule().stroke(draft.tint.opacity(0.35), lineWidth: 1))
                }

                PrimaryButton(title: isNew ? "Add counter" : "Save changes", symbol: "checkmark") {
                    var counter = draft
                    counter.title = counter.title.trimmingCharacters(in: .whitespaces)
                    counter.abbreviation = resolvedAbbreviation
                    onSave(counter)
                    dismiss()
                }
                .opacity(canSave ? 1 : 0.4)
                .disabled(!canSave)

                if !isNew {
                    SecondaryButton(title: "Delete counter", symbol: "trash", tint: Theme.danger) {
                        confirmDelete = true
                    }
                }
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .background(Theme.surface.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .confirmationDialog("Delete this counter?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It disappears from every panel. Totals already counted are kept in case you add it back.")
        }
    }

    private var header: some View {
        HStack {
            Text(isNew ? "New counter" : "Edit counter")
                .font(.tally(26, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.surfaceHigh))
            }
            .buttonStyle(.plain)
        }
    }
}

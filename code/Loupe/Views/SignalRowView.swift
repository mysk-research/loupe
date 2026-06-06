//
//  SignalRowView.swift
//  Loupe
//
//  Single row inside a category detail. Shows the signal name, a
//  monospaced value, and an explanatory footnote.
//  Long press copies the raw value to the clipboard.
//

import SwiftUI

struct SignalRowView: View {
    let signal: FingerprintSignal

    @State private var copied = false
    @State private var resetCopiedTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(signal.name)
                .font(.subheadline.weight(.semibold))
            valueContent
            if !signal.rationale.isEmpty {
                Text(signal.rationale)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if copied {
                Label("Copied", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Copy value") {
            copyValue()
        }
        .contextMenu {
            Button {
                copyValue()
            } label: {
                Label("Copy value", systemImage: "doc.on.doc")
            }
            Button {
                PlatformPasteboard.setString("\(signal.name): \(signal.value)")
                showCopied()
            } label: {
                Label("Copy as key: value", systemImage: "doc.on.clipboard")
            }
        }
        .onDisappear {
            resetCopiedTask?.cancel()
            resetCopiedTask = nil
        }
    }

    // MARK: - Value Content

    @ViewBuilder
    private var valueContent: some View {
        switch signal.displayHint {
        case .plain:
            plainValue
        case .keyValue:
            if let entries = signal.entries, !entries.isEmpty {
                keyValueContent(entries)
            } else {
                plainValue
            }
        case .axis:
            if let entries = signal.entries, !entries.isEmpty {
                axisContent(entries)
            } else {
                plainValue
            }
        case .tags:
            if let entries = signal.entries, !entries.isEmpty {
                tagsContent(entries)
            } else {
                plainValue
            }
        case .compound:
            if let entries = signal.entries, !entries.isEmpty {
                compoundContent(entries)
            } else {
                plainValue
            }
        }
    }

    private var plainValue: some View {
        Text(signal.value)
            .font(.system(.callout, design: .monospaced))
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Key-Value

    private func keyValueContent(_ entries: [SignalEntry]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entries, id: \.self) { entry in
                LabeledContent {
                    Text(entry.value)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                } label: {
                    Text(entry.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Axis / Vector

    private func axisContent(_ entries: [SignalEntry]) -> some View {
        HStack(spacing: 12) {
            ForEach(entries, id: \.self) { entry in
                VStack(spacing: 2) {
                    Text(entry.label)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(entry.value)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Tags / Chips

    private func tagsContent(_ entries: [SignalEntry]) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(entries, id: \.self) { entry in
                Text(entry.label)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Compound

    private func compoundContent(_ entries: [SignalEntry]) -> some View {
        HStack(spacing: 16) {
            ForEach(entries, id: \.self) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.value)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.primary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Clipboard

    private func copyValue() {
        PlatformPasteboard.setString(signal.value)
        showCopied()
    }

    private func showCopied() {
        resetCopiedTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { copied = true }
        resetCopiedTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { copied = false }
            resetCopiedTask = nil
        }
    }
}

// MARK: - Flow Layout

/// A simple wrapping horizontal layout for tag chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        guard !rows.isEmpty else { return .zero }
        let height = rows.reduce(CGFloat.zero) { total, row in
            total + row.height + (total > 0 ? spacing : 0)
        }
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        var subviewIndex = 0
        for row in rows {
            var x = bounds.minX
            for size in row.sizes {
                subviews[subviewIndex].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + spacing
                subviewIndex += 1
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var sizes: [CGSize]
        var width: CGFloat
        var height: CGFloat
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(sizes: [], width: 0, height: 0)

        for subview in subviews {
            let size = sizeThatFits(subview: subview, maxWidth: maxWidth)
            let newWidth = currentRow.width + (currentRow.sizes.isEmpty ? 0 : spacing) + size.width
            if !currentRow.sizes.isEmpty && newWidth > maxWidth {
                rows.append(currentRow)
                currentRow = Row(sizes: [size], width: size.width, height: size.height)
            } else {
                currentRow.sizes.append(size)
                currentRow.width = newWidth
                currentRow.height = max(currentRow.height, size.height)
            }
        }
        if !currentRow.sizes.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }

    private func sizeThatFits(subview: LayoutSubview, maxWidth: CGFloat) -> CGSize {
        guard maxWidth.isFinite else {
            return subview.sizeThatFits(.unspecified)
        }
        let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
        return CGSize(width: min(size.width, maxWidth), height: size.height)
    }
}

import AppKit
import CodexBarCore
import SwiftUI

@MainActor
struct MenuContent: View {
    @Bindable var store: UsageStore
    @Bindable var settings: SettingsStore
    let account: AccountInfo
    let updater: UpdaterProviding
    let provider: UsageProvider?
    let actions: MenuActions

    var body: some View {
        let descriptor = MenuDescriptor.build(
            provider: self.provider,
            store: self.store,
            settings: self.settings,
            account: self.account,
            updateReady: self.updater.updateStatus.isUpdateReady)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(descriptor.sections.enumerated()), id: \.offset) { index, section in
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(section.entries.enumerated()), id: \.offset) { _, entry in
                        self.row(for: entry)
                    }
                }
                if index < descriptor.sections.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minWidth: 260, alignment: .leading)
    }

    @ViewBuilder
    private func row(for entry: MenuDescriptor.Entry) -> some View {
        switch entry {
        case let .text(text, style):
            switch style {
            case .headline:
                Text(text).font(.headline)
                    .accessibilityLabel(text)
            case .primary:
                Text(text)
                    .accessibilityLabel(text)
            case .secondary:
                Text(text).foregroundStyle(.secondary).font(.footnote)
                    .accessibilityLabel(text)
            }
        case let .action(title, action):
            Button {
                self.perform(action)
            } label: {
                if let icon = self.iconName(for: action) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .imageScale(.medium)
                            .frame(width: 18, alignment: .center)
                        Text(title)
                    }
                    .foregroundStyle(.primary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(title)
                } else {
                    Text(title)
                        .accessibilityLabel(title)
                }
            }
            .buttonStyle(.plain)
        case let .debugLayoutProbe(title, action, systemImageName, isEnabled, iconPointSize):
            Button {
                self.perform(action)
            } label: {
                if let systemImageName {
                    HStack(spacing: 8) {
                        Image(systemName: systemImageName)
                            .font(.system(size: CGFloat(iconPointSize)))
                            .imageScale(.medium)
                            .frame(width: 18, alignment: .center)
                        Text(title)
                    }
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(title)
                } else {
                    Text(title)
                        .foregroundStyle(isEnabled ? .primary : .secondary)
                        .accessibilityLabel(title)
                }
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        case let .submenu(title, systemImageName, submenuItems):
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if let systemImageName {
                        Image(systemName: systemImageName)
                    }
                    Text(title).font(.headline)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(title)
                ForEach(Array(submenuItems.enumerated()), id: \.offset) { _, submenuItem in
                    HStack(spacing: 8) {
                        if submenuItem.isChecked {
                            Image(systemName: "checkmark")
                                .imageScale(.small)
                                .frame(width: 18, alignment: .center)
                        } else {
                            Spacer().frame(width: 18)
                        }
                        Text(submenuItem.title)
                            .foregroundStyle(submenuItem.isEnabled ? .primary : .secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(submenuItem.title)
                }
            }
        case .divider:
            Divider()
        }
    }

    private func iconName(for action: MenuDescriptor.MenuAction) -> String? {
        action.systemImageName
    }

    private func perform(_ action: MenuDescriptor.MenuAction) {
        switch action {
        case .refresh:
            self.actions.refresh()
        case .refreshAugmentSession:
            self.actions.refreshAugmentSession()
        case .installUpdate:
            self.actions.installUpdate()
        case .dashboard:
            self.actions.openDashboard()
        case .statusPage:
            self.actions.openStatusPage()
        case .changelog:
            self.actions.openChangelog()
        case .addCodexAccount:
            self.actions.addCodexAccount()
        case .requestCodexSystemPromotion:
            return
        case let .addProviderAccount(provider):
            self.actions.switchAccount(provider)
        case let .switchAccount(provider):
            self.actions.switchAccount(provider)
        case let .openTerminal(command):
            self.actions.openTerminal(command)
        case let .loginToProvider(url):
            if let urlObj = URL(string: url) {
                NSWorkspace.shared.open(urlObj)
            }
        case .settings:
            self.actions.openSettings()
        case .about:
            self.actions.openAbout()
        case .quit:
            self.actions.quit()
        case let .copyError(message):
            self.actions.copyError(message)
        }
    }
}

struct MenuActions {
    let installUpdate: () -> Void
    let refresh: () -> Void
    let refreshAugmentSession: () -> Void
    let openDashboard: () -> Void
    let openStatusPage: () -> Void
    let openChangelog: () -> Void
    let addCodexAccount: () -> Void
    let switchAccount: (UsageProvider) -> Void
    let openTerminal: (String) -> Void
    let openSettings: () -> Void
    let openAbout: () -> Void
    let quit: () -> Void
    let copyError: (String) -> Void
}

struct PersistentRefreshRowMetrics: Equatable {
    enum Key: String, CaseIterable, Identifiable {
        case rowHeight
        case selectionHorizontalInset
        case selectionVerticalInset
        case selectionCornerRadius
        case leadingPadding
        case trailingPadding
        case iconWidth
        case iconSymbolPointSize
        case iconSymbolWeight
        case iconTitleSpacing
        case shortcutFontSize
        case shortcutXOffset
        case shortcutYOffset

        var id: String {
            self.rawValue
        }

        var title: String {
            switch self {
            case .rowHeight: "Row height"
            case .selectionHorizontalInset: "Selection horizontal inset"
            case .selectionVerticalInset: "Selection vertical inset"
            case .selectionCornerRadius: "Selection corner radius"
            case .leadingPadding: "Leading padding"
            case .trailingPadding: "Trailing padding"
            case .iconWidth: "Icon width"
            case .iconSymbolPointSize: "Icon point size"
            case .iconSymbolWeight: "Icon weight"
            case .iconTitleSpacing: "Icon-title spacing"
            case .shortcutFontSize: "Shortcut font size"
            case .shortcutXOffset: "Shortcut X offset"
            case .shortcutYOffset: "Shortcut Y offset"
            }
        }

        var range: ClosedRange<Double> {
            switch self {
            case .rowHeight: 18...30
            case .selectionHorizontalInset: 0...10
            case .selectionVerticalInset: 0...4
            case .selectionCornerRadius: 0...10
            case .leadingPadding: 8...20
            case .trailingPadding: 0...16
            case .iconWidth: 12...22
            case .iconSymbolPointSize: 8...16
            case .iconSymbolWeight: 0...3
            case .iconTitleSpacing: 0...10
            case .shortcutFontSize: 10...16
            case .shortcutXOffset: -24...4
            case .shortcutYOffset: -4...4
            }
        }

        var step: Double {
            switch self {
            case .iconTitleSpacing:
                0.5
            default:
                1
            }
        }

        var defaultValue: Double {
            let defaults = PersistentRefreshRowMetrics.defaults
            return switch self {
            case .rowHeight: Double(defaults.rowHeight)
            case .selectionHorizontalInset: Double(defaults.selectionHorizontalInset)
            case .selectionVerticalInset: Double(defaults.selectionVerticalInset)
            case .selectionCornerRadius: Double(defaults.selectionCornerRadius)
            case .leadingPadding: Double(defaults.leadingPadding)
            case .trailingPadding: Double(defaults.trailingPadding)
            case .iconWidth: Double(defaults.iconWidth)
            case .iconSymbolPointSize: Double(defaults.iconSymbolPointSize)
            case .iconSymbolWeight: Double(defaults.iconSymbolWeight)
            case .iconTitleSpacing: Double(defaults.iconTitleSpacing)
            case .shortcutFontSize: Double(defaults.shortcutFontSize)
            case .shortcutXOffset: Double(defaults.shortcutXOffset)
            case .shortcutYOffset: Double(defaults.shortcutYOffset)
            }
        }

        func sanitized(_ value: Double) -> Double {
            let clamped = min(max(value, self.range.lowerBound), self.range.upperBound)
            return (clamped / self.step).rounded() * self.step
        }
    }

    static let defaults = Self(
        rowHeight: 24,
        selectionHorizontalInset: 5,
        selectionVerticalInset: 0,
        selectionCornerRadius: 7,
        // Align the custom row's image/title frames with native NSMenuItem columns.
        leadingPadding: 13,
        trailingPadding: 8,
        iconWidth: 17,
        iconSymbolPointSize: 11,
        iconSymbolWeight: 0,
        iconTitleSpacing: 4.5,
        shortcutFontSize: 13,
        shortcutXOffset: -12,
        shortcutYOffset: 0)

    let rowHeight: CGFloat
    let selectionHorizontalInset: CGFloat
    let selectionVerticalInset: CGFloat
    let selectionCornerRadius: CGFloat
    let leadingPadding: CGFloat
    let trailingPadding: CGFloat
    let iconWidth: CGFloat
    let iconSymbolPointSize: CGFloat
    let iconSymbolWeight: CGFloat
    let iconTitleSpacing: CGFloat
    let shortcutFontSize: CGFloat
    let shortcutXOffset: CGFloat
    let shortcutYOffset: CGFloat

    init(
        rowHeight: CGFloat,
        selectionHorizontalInset: CGFloat,
        selectionVerticalInset: CGFloat,
        selectionCornerRadius: CGFloat,
        leadingPadding: CGFloat,
        trailingPadding: CGFloat,
        iconWidth: CGFloat,
        iconSymbolPointSize: CGFloat,
        iconSymbolWeight: CGFloat,
        iconTitleSpacing: CGFloat,
        shortcutFontSize: CGFloat,
        shortcutXOffset: CGFloat,
        shortcutYOffset: CGFloat)
    {
        self.rowHeight = rowHeight
        self.selectionHorizontalInset = selectionHorizontalInset
        self.selectionVerticalInset = selectionVerticalInset
        self.selectionCornerRadius = selectionCornerRadius
        self.leadingPadding = leadingPadding
        self.trailingPadding = trailingPadding
        self.iconWidth = iconWidth
        self.iconSymbolPointSize = iconSymbolPointSize
        self.iconSymbolWeight = iconSymbolWeight
        self.iconTitleSpacing = iconTitleSpacing
        self.shortcutFontSize = shortcutFontSize
        self.shortcutXOffset = shortcutXOffset
        self.shortcutYOffset = shortcutYOffset
    }

    init(overrides: [String: Double], defaultMetrics: Self = .defaults) {
        self.init(
            rowHeight: CGFloat(Self.value(.rowHeight, overrides: overrides, defaults: defaultMetrics)),
            selectionHorizontalInset: CGFloat(
                Self.value(.selectionHorizontalInset, overrides: overrides, defaults: defaultMetrics)),
            selectionVerticalInset: CGFloat(
                Self.value(.selectionVerticalInset, overrides: overrides, defaults: defaultMetrics)),
            selectionCornerRadius: CGFloat(
                Self.value(.selectionCornerRadius, overrides: overrides, defaults: defaultMetrics)),
            leadingPadding: CGFloat(Self.value(.leadingPadding, overrides: overrides, defaults: defaultMetrics)),
            trailingPadding: CGFloat(Self.value(.trailingPadding, overrides: overrides, defaults: defaultMetrics)),
            iconWidth: CGFloat(Self.value(.iconWidth, overrides: overrides, defaults: defaultMetrics)),
            iconSymbolPointSize: CGFloat(
                Self.value(.iconSymbolPointSize, overrides: overrides, defaults: defaultMetrics)),
            iconSymbolWeight: CGFloat(Self.value(.iconSymbolWeight, overrides: overrides, defaults: defaultMetrics)),
            iconTitleSpacing: CGFloat(Self.value(.iconTitleSpacing, overrides: overrides, defaults: defaultMetrics)),
            shortcutFontSize: CGFloat(Self.value(.shortcutFontSize, overrides: overrides, defaults: defaultMetrics)),
            shortcutXOffset: CGFloat(Self.value(.shortcutXOffset, overrides: overrides, defaults: defaultMetrics)),
            shortcutYOffset: CGFloat(Self.value(.shortcutYOffset, overrides: overrides, defaults: defaultMetrics)))
    }

    private static func value(_ key: Key, overrides: [String: Double], defaults: Self) -> Double {
        let fallback = switch key {
        case .rowHeight: Double(defaults.rowHeight)
        case .selectionHorizontalInset: Double(defaults.selectionHorizontalInset)
        case .selectionVerticalInset: Double(defaults.selectionVerticalInset)
        case .selectionCornerRadius: Double(defaults.selectionCornerRadius)
        case .leadingPadding: Double(defaults.leadingPadding)
        case .trailingPadding: Double(defaults.trailingPadding)
        case .iconWidth: Double(defaults.iconWidth)
        case .iconSymbolPointSize: Double(defaults.iconSymbolPointSize)
        case .iconSymbolWeight: Double(defaults.iconSymbolWeight)
        case .iconTitleSpacing: Double(defaults.iconTitleSpacing)
        case .shortcutFontSize: Double(defaults.shortcutFontSize)
        case .shortcutXOffset: Double(defaults.shortcutXOffset)
        case .shortcutYOffset: Double(defaults.shortcutYOffset)
        }
        guard let override = overrides[key.rawValue] else { return fallback }
        return key.sanitized(override)
    }
}

@MainActor
struct StatusIconView: View {
    @Bindable var store: UsageStore
    let provider: UsageProvider

    var body: some View {
        Image(nsImage: self.icon)
            .renderingMode(.template)
            .interpolation(.none)
            .accessibilityLabel(self.accessibilityLabel)
            .accessibilityValue(self.accessibilityValue)
    }

    private var accessibilityLabel: String {
        let descriptor = ProviderDescriptorRegistry.descriptor(for: self.provider)
        return descriptor.metadata.displayName
    }

    private var accessibilityValue: String {
        let snapshot = self.store.snapshot(for: self.provider)
        guard let snap = snapshot else {
            return L("No data")
        }
        let remaining = IconRemainingResolver.resolvedRemaining(
            snapshot: snap,
            style: self.store.style(for: self.provider))
        let primary = remaining.primary
        let percent = primary.map(Self.accessibilityPercentRemaining) ?? L("Unknown")
        let stale = self.store.isStale(provider: self.provider)
        return stale ? "\(percent), \(L("stale data"))" : percent
    }

    static func accessibilityPercentRemaining(_ remaining: Double) -> String {
        String(format: L("%d percent remaining"), Int(remaining.rounded()))
    }

    private var icon: NSImage {
        let snapshot = self.store.snapshot(for: self.provider)
        let remaining = snapshot.map {
            IconRemainingResolver.resolvedRemaining(snapshot: $0, style: self.store.style(for: self.provider))
        }
        let creditsProjection = self.store.codexConsumerProjectionIfNeeded(
            for: self.provider,
            surface: .menuBar,
            snapshotOverride: snapshot,
            now: snapshot?.updatedAt ?? Date())
        let creditsRemaining = creditsProjection?.menuBarFallback == .creditsBalance
            ? self.store.codexMenuBarCreditsRemaining(
                snapshotOverride: snapshot,
                now: snapshot?.updatedAt ?? Date())
            : nil
        return IconRenderer.makeIcon(
            primaryRemaining: remaining?.primary,
            weeklyRemaining: remaining?.secondary,
            creditsRemaining: creditsRemaining,
            stale: self.store.isStale(provider: self.provider),
            style: self.store.style(for: self.provider),
            statusIndicator: self.store.statusIndicator(for: self.provider),
            hideCritters: self.store.settings.menuBarHidesCritters)
    }
}

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

enum PersistentMenuShortcutColorMode: String, CaseIterable, Identifiable {
    case secondary
    case primary
    case tertiary

    var id: String {
        self.rawValue
    }

    var displayName: String {
        switch self {
        case .secondary:
            "Secondary"
        case .primary:
            "Primary"
        case .tertiary:
            "Tertiary"
        }
    }

    func color(isHighlighted: Bool) -> Color {
        guard !isHighlighted else { return MenuHighlightStyle.selectionText }

        switch self {
        case .secondary:
            return MenuHighlightStyle.normalSecondaryText
        case .primary:
            return MenuHighlightStyle.normalPrimaryText
        case .tertiary:
            return Color(nsColor: .tertiaryLabelColor)
        }
    }
}

struct PersistentMenuActionRowMetrics: Equatable {
    static let debugRowHeightKey = "debugPersistentRefreshRowHeight"
    static let debugSelectionHorizontalInsetKey = "debugPersistentRefreshSelectionHorizontalInset"
    static let debugSelectionVerticalInsetKey = "debugPersistentRefreshSelectionVerticalInset"
    static let debugSelectionCornerRadiusKey = "debugPersistentRefreshSelectionCornerRadius"
    static let debugLeadingPaddingKey = "debugPersistentRefreshLeadingPadding"
    static let debugTrailingPaddingKey = "debugPersistentRefreshTrailingPadding"
    static let debugIconWidthKey = "debugPersistentRefreshIconWidth"
    static let debugIconTitleSpacingKey = "debugPersistentRefreshIconTitleSpacing"
    static let debugShortcutXOffsetKey = "debugPersistentRefreshShortcutXOffset"
    static let debugShortcutYOffsetKey = "debugPersistentRefreshShortcutYOffset"
    static let debugShortcutColorModeKey = "debugPersistentRefreshShortcutColorMode"

    static let defaults = Self(
        rowHeight: 28,
        selectionHorizontalInset: 6,
        selectionVerticalInset: 1,
        selectionCornerRadius: 6,
        leadingPadding: 15,
        trailingPadding: 8,
        iconWidth: 18,
        iconTitleSpacing: 6,
        shortcutXOffset: 0,
        shortcutYOffset: 0,
        shortcutColorMode: .secondary)

    static var current: Self {
        let defaults = UserDefaults.standard
        let fallback = Self.defaults
        return Self(
            rowHeight: Self.double(
                for: Self.debugRowHeightKey,
                defaults: defaults,
                fallback: fallback.rowHeight),
            selectionHorizontalInset: Self.double(
                for: Self.debugSelectionHorizontalInsetKey,
                defaults: defaults,
                fallback: fallback.selectionHorizontalInset),
            selectionVerticalInset: Self.double(
                for: Self.debugSelectionVerticalInsetKey,
                defaults: defaults,
                fallback: fallback.selectionVerticalInset),
            selectionCornerRadius: Self.double(
                for: Self.debugSelectionCornerRadiusKey,
                defaults: defaults,
                fallback: fallback.selectionCornerRadius),
            leadingPadding: Self.double(
                for: Self.debugLeadingPaddingKey,
                defaults: defaults,
                fallback: fallback.leadingPadding),
            trailingPadding: Self.double(
                for: Self.debugTrailingPaddingKey,
                defaults: defaults,
                fallback: fallback.trailingPadding),
            iconWidth: Self.double(
                for: Self.debugIconWidthKey,
                defaults: defaults,
                fallback: fallback.iconWidth),
            iconTitleSpacing: Self.double(
                for: Self.debugIconTitleSpacingKey,
                defaults: defaults,
                fallback: fallback.iconTitleSpacing),
            shortcutXOffset: Self.double(
                for: Self.debugShortcutXOffsetKey,
                defaults: defaults,
                fallback: fallback.shortcutXOffset),
            shortcutYOffset: Self.double(
                for: Self.debugShortcutYOffsetKey,
                defaults: defaults,
                fallback: fallback.shortcutYOffset),
            shortcutColorMode: Self.shortcutColorMode(defaults: defaults, fallback: fallback.shortcutColorMode))
    }

    let rowHeight: CGFloat
    let selectionHorizontalInset: CGFloat
    let selectionVerticalInset: CGFloat
    let selectionCornerRadius: CGFloat
    let leadingPadding: CGFloat
    let trailingPadding: CGFloat
    let iconWidth: CGFloat
    let iconTitleSpacing: CGFloat
    let shortcutXOffset: CGFloat
    let shortcutYOffset: CGFloat
    let shortcutColorMode: PersistentMenuShortcutColorMode

    private static func double(for key: String, defaults: UserDefaults, fallback: CGFloat) -> CGFloat {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return CGFloat(defaults.double(forKey: key))
    }

    private static func shortcutColorMode(
        defaults: UserDefaults,
        fallback: PersistentMenuShortcutColorMode) -> PersistentMenuShortcutColorMode
    {
        guard let rawValue = defaults.string(forKey: debugShortcutColorModeKey) else { return fallback }
        return PersistentMenuShortcutColorMode(rawValue: rawValue) ?? fallback
    }
}

struct PersistentMenuActionRowView: View {
    static var rowHeight: CGFloat {
        PersistentMenuActionRowMetrics.current.rowHeight
    }

    private static let menuFontSize = NSFont.menuFont(ofSize: 0).pointSize
    private static let menuFont = Font.system(size: Self.menuFontSize)

    let title: String
    let systemImageName: String?
    let shortcutText: String?
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        let metrics = PersistentMenuActionRowMetrics.current

        HStack(spacing: metrics.iconTitleSpacing) {
            if let systemImageName {
                Image(systemName: systemImageName)
                    .font(Self.menuFont)
                    .frame(width: metrics.iconWidth, alignment: .center)
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
            }
            Text(self.title)
                .font(Self.menuFont)
                .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
            Spacer(minLength: 0)
            if let shortcutText {
                Text(shortcutText)
                    .font(Self.menuFont)
                    .foregroundStyle(metrics.shortcutColorMode.color(isHighlighted: self.isHighlighted))
                    .offset(x: metrics.shortcutXOffset, y: metrics.shortcutYOffset)
            }
        }
        .padding(.leading, metrics.leadingPadding)
        .padding(.trailing, metrics.trailingPadding)
        .frame(height: metrics.rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.title)
    }
}

struct PersistentMenuActionRowContainerView<Content: View>: View {
    @Bindable var highlightState: MenuCardHighlightState
    @ViewBuilder let content: () -> Content

    var body: some View {
        let metrics = PersistentMenuActionRowMetrics.current

        self.content()
            .environment(\.menuItemHighlighted, self.highlightState.isHighlighted)
            .background {
                if self.highlightState.isHighlighted {
                    NativeMenuSelectionBackground()
                        .clipShape(RoundedRectangle(cornerRadius: metrics.selectionCornerRadius, style: .continuous))
                        .padding(.horizontal, metrics.selectionHorizontalInset)
                        .padding(.vertical, metrics.selectionVerticalInset)
                }
            }
    }
}

struct NativeMenuSelectionBackground: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        Self.configure(view)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context _: Context) {
        Self.configure(nsView)
    }

    private static func configure(_ view: NSVisualEffectView) {
        view.material = .selection
        view.blendingMode = .withinWindow
        view.state = .active
        view.isEmphasized = true
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

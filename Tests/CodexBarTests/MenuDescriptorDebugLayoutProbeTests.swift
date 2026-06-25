import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct MenuDescriptorDebugLayoutProbeTests {
    @Test
    func `debug layout probe is hidden by default`() {
        let descriptor = self.makeDescriptor(
            provider: .antigravity,
            suite: "MenuDescriptorDebugLayoutProbeTests-default")

        #expect(self.debugProbeRows(in: descriptor).isEmpty)
    }

    @Test
    func `affected provider scope adds probe only to affected provider menus`() {
        let antigravityDescriptor = self.makeDescriptor(
            provider: .antigravity,
            suite: "MenuDescriptorDebugLayoutProbeTests-affected-antigravity",
            configure: { settings in
                settings.debugMenuLayoutProbeScope = .affectedProviders
                settings.debugMenuLayoutProbeAction = .dashboard
                settings.debugMenuLayoutProbeIcon = .actionDefault
                settings.debugMenuLayoutProbeTitle = .short
            })
        let codexDescriptor = self.makeDescriptor(
            provider: .codex,
            suite: "MenuDescriptorDebugLayoutProbeTests-affected-codex",
            configure: { settings in
                settings.debugMenuLayoutProbeScope = .affectedProviders
            })

        let rows = self.debugProbeRows(in: antigravityDescriptor)
        #expect(rows.count == 1)
        #expect(rows.first?.title == "X")
        #expect(rows.first?.action == .dashboard)
        #expect(rows.first?.systemImageName == MenuDescriptor.MenuActionSystemImage.dashboard.rawValue)
        #expect(rows.first?.isEnabled == true)
        #expect(rows.first?.iconPointSize == DebugMenuLayoutProbeIconSize.defaultValue)
        #expect(self.debugProbeRows(in: codexDescriptor).isEmpty)
    }

    @Test
    func `overview scope adds probe to persistent section before refresh`() {
        let descriptor = self.makeDescriptor(
            provider: nil,
            suite: "MenuDescriptorDebugLayoutProbeTests-overview",
            includeContextualActions: false,
            configure: { settings in
                settings.debugMenuLayoutProbeScope = .overview
                settings.debugMenuLayoutProbeAction = .settings
                settings.debugMenuLayoutProbeIcon = .none
                settings.debugMenuLayoutProbeTitle = .dashboard
                settings.debugMenuLayoutProbeItemEnabled = false
                settings.debugMenuLayoutProbeIconPointSize = 14
            })

        let persistentEntries = descriptor.sections.last?.entries ?? []
        #expect(self.debugProbeRows(in: descriptor) == [
            DebugProbeRow(
                title: "Usage Dashboard",
                action: .settings,
                systemImageName: nil,
                isEnabled: false,
                iconPointSize: 14),
        ])
        #expect(persistentEntries.first?.isDebugLayoutProbe == true)
        #expect(persistentEntries.dropFirst().first?.actionTitle == "Refresh")
    }

    @Test
    func `debug layout probe can test alternate dashboard icons`() {
        let cases: [(DebugMenuLayoutProbeIcon, String)] = [
            (.chartBarHorizontalPage, "chart.bar.horizontal.page"),
            (.chartLineTextClipboard, "chart.line.text.clipboard"),
            (.waveformECGTextClipboard, "waveform.path.ecg.text.clipboard"),
            (.chartBarDocHorizontal, "chart.bar.doc.horizontal"),
            (.chartPie, "chart.pie"),
            (.chartLineCircle, "chart.line.uptrend.xyaxis.circle"),
            (.gaugeDots, "gauge.with.dots.needle.67percent"),
            (.rectangleGroup, "rectangle.3.group"),
        ]

        for (icon, expectedName) in cases {
            let descriptor = self.makeDescriptor(
                provider: .antigravity,
                suite: "MenuDescriptorDebugLayoutProbeTests-\(icon.rawValue)",
                configure: { settings in
                    settings.debugMenuLayoutProbeScope = .affectedProviders
                    settings.debugMenuLayoutProbeIcon = icon
                })

            #expect(self.debugProbeRows(in: descriptor).first?.systemImageName == expectedName)
        }
    }

    private func makeDescriptor(
        provider: UsageProvider?,
        suite: String,
        includeContextualActions: Bool = true,
        configure: (SettingsStore) -> Void = { _ in }) -> MenuDescriptor
    {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let settings = SettingsStore(
            userDefaults: defaults,
            configStore: testConfigStore(suiteName: suite),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.statusChecksEnabled = false
        configure(settings)

        let fetcher = UsageFetcher(environment: [:])
        let store = UsageStore(
            fetcher: fetcher,
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            startupBehavior: .testing)

        return MenuDescriptor.build(
            provider: provider,
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updateReady: false,
            includeContextualActions: includeContextualActions)
    }

    private func debugProbeRows(in descriptor: MenuDescriptor) -> [DebugProbeRow] {
        descriptor.sections
            .flatMap(\.entries)
            .compactMap { entry -> DebugProbeRow? in
                guard case let .debugLayoutProbe(title, action, systemImageName, isEnabled, iconPointSize) = entry
                else {
                    return nil
                }
                return DebugProbeRow(
                    title: title,
                    action: action,
                    systemImageName: systemImageName,
                    isEnabled: isEnabled,
                    iconPointSize: iconPointSize)
            }
    }
}

private struct DebugProbeRow: Equatable {
    var title: String
    var action: MenuDescriptor.MenuAction
    var systemImageName: String?
    var isEnabled: Bool
    var iconPointSize: Double
}

extension MenuDescriptor.Entry {
    fileprivate var isDebugLayoutProbe: Bool {
        if case .debugLayoutProbe = self { return true }
        return false
    }

    fileprivate var actionTitle: String? {
        guard case let .action(title, _) = self else { return nil }
        return title
    }
}

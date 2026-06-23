import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

@MainActor
@Suite(.serialized)
struct StatusMenuPersistentRefreshAppearanceTests {
    @Test
    func `refresh row metrics match tuned native-style values`() {
        let metrics = PersistentMenuActionRowMetrics.defaults
        #expect(metrics.rowHeight == 24)
        #expect(metrics.selectionHorizontalInset == 5)
        #expect(metrics.selectionVerticalInset == 0)
        #expect(metrics.selectionCornerRadius == 7)
        #expect(metrics.leadingPadding == 16)
        #expect(metrics.trailingPadding == 8)
        #expect(metrics.iconWidth == 17)
        #expect(metrics.iconSymbolPointSize == 11)
        #expect(metrics.iconTitleSpacing == 4.5)
        #expect(metrics.shortcutFontSize == 13)
        #expect(metrics.shortcutXOffset == -12)
        #expect(metrics.shortcutYOffset == 0)
    }

    private func makeSettings() -> SettingsStore {
        let suite = "StatusMenuPersistentRefreshAppearanceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        return SettingsStore(
            userDefaults: defaults,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
    }

    private func makeController(settings: SettingsStore) -> StatusItemController {
        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        return StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: .system)
    }

    @Test
    func `refresh shortcut display has stable native-style column`() throws {
        let previousRendering = StatusItemController.menuCardRenderingEnabled
        StatusItemController.menuCardRenderingEnabled = true
        defer { StatusItemController.menuCardRenderingEnabled = previousRendering }

        let settings = self.makeSettings()
        settings.refreshFrequency = .manual
        settings.mergeIcons = false

        let controller = self.makeController(settings: settings)
        let menu = controller.makeMenu(for: .codex)
        controller.menuWillOpen(menu)

        let refreshItem = try #require(menu.items.first { $0.title == "Refresh" })
        let refreshView = try #require(refreshItem.view as? PersistentMenuActionView)
        refreshView.applySize(width: 320, height: PersistentMenuActionRowMetrics.defaults.rowHeight)
        refreshView.layoutSubtreeIfNeeded()

        let shortcutField = try #require(
            refreshView.subviews.compactMap { $0 as? NSTextField }.first { $0.stringValue == "⌘ R" })
        #expect(shortcutField.alignment == .left)
        #expect(shortcutField.lineBreakMode == .byClipping)
        #expect(shortcutField.frame.width >= 40)
        let shortcutFont = try #require(shortcutField.font)
        #expect(abs(shortcutFont.pointSize - PersistentMenuActionRowMetrics.defaults.shortcutFontSize) < 0.001)

        let iconView = try #require(refreshView.subviews.compactMap { $0 as? NSImageView }.first)
        #expect(iconView.frame.width == PersistentMenuActionRowMetrics.defaults.iconWidth)
        #expect(iconView.frame.height == PersistentMenuActionRowMetrics.defaults.iconWidth)
    }

    @Test
    func `bottom action rows share leading geometry`() throws {
        let previousRendering = StatusItemController.menuCardRenderingEnabled
        StatusItemController.menuCardRenderingEnabled = true
        defer { StatusItemController.menuCardRenderingEnabled = previousRendering }

        let settings = self.makeSettings()
        settings.refreshFrequency = .manual
        settings.mergeIcons = false

        let controller = self.makeController(settings: settings)
        let menu = controller.makeMenu(for: .codex)
        controller.menuWillOpen(menu)

        let titles = ["Refresh", "Settings...", "About CodexBar", "Quit"]
        let rows = try titles.map { title -> (String, PersistentMenuActionView) in
            let item = try #require(menu.items.first { $0.title == title })
            let view = try #require(item.view as? PersistentMenuActionView)
            view.applySize(width: 320, height: PersistentMenuActionRowMetrics.defaults.rowHeight)
            view.layoutSubtreeIfNeeded()
            return (title, view)
        }

        let iconOrigins = try rows.map { title, view -> CGFloat in
            let iconView = try #require(view.subviews.compactMap { $0 as? NSImageView }.first, "\(title) icon")
            return iconView.frame.minX
        }
        let titleOrigins = try rows.map { title, view -> CGFloat in
            let titleField = try #require(
                view.subviews.compactMap { $0 as? NSTextField }.first { $0.stringValue == title },
                "\(title) label")
            return titleField.frame.minX
        }

        #expect(iconOrigins.allSatisfy { abs($0 - iconOrigins[0]) <= 0.5 })
        #expect(titleOrigins.allSatisfy { abs($0 - titleOrigins[0]) <= 0.5 })

        let shortcutRows = try rows.filter { $0.0 != "About CodexBar" }.map { title, view -> CGFloat in
            let field = try #require(
                view.subviews.compactMap { $0 as? NSTextField }.first { $0.stringValue.hasPrefix("⌘") },
                "\(title) shortcut")
            #expect(field.alignment == .left)
            return field.frame.minX
        }
        #expect(shortcutRows.allSatisfy { abs($0 - shortcutRows[0]) <= 0.5 })
    }

    @Test
    func `refresh row width follows final rendered menu width`() {
        let settings = self.makeSettings()
        let controller = self.makeController(settings: settings)
        defer { controller.releaseStatusItemsForTesting() }

        let metrics = PersistentMenuActionRowMetrics.defaults
        let refreshView = PersistentMenuActionView(
            title: "Refresh",
            systemImageName: "arrow.clockwise",
            shortcutText: "⌘ R")
        refreshView.applySize(width: StatusItemController.menuCardBaseWidth, height: metrics.rowHeight)
        refreshView.frame.origin.x = 4

        let refreshItem = NSMenuItem()
        refreshItem.title = "Refresh"
        refreshItem.view = refreshView

        let wideNativeItem = NSMenuItem(
            title: String(repeating: "W", count: 60),
            action: nil,
            keyEquivalent: "")
        let menu = NSMenu()
        menu.addItem(refreshItem)
        menu.addItem(wideNativeItem)

        let expectedWidth = controller.renderedMenuWidth(for: menu)
        #expect(expectedWidth > StatusItemController.menuCardBaseWidth)

        controller.refreshMenuCardHeights(in: menu)

        #expect(abs(refreshView.frame.width - expectedWidth) <= 0.5)
        #expect(refreshView.frame.origin == .zero)
        #expect(refreshView.frame.height == metrics.rowHeight)
    }
}

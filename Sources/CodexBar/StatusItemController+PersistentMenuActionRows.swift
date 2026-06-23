import AppKit

extension StatusItemController {
    private static let persistentActionMenuItemIDPrefix = "persistentMenuAction:"

    func isPersistentMenuAction(_ action: MenuDescriptor.MenuAction) -> Bool {
        switch action {
        case .refresh, .settings, .about, .quit:
            true
        default:
            false
        }
    }

    func trackPersistentRefreshItemIfNeeded(_ item: NSMenuItem) {
        guard self.isPersistentRefreshItem(item) else { return }
        self.persistentRefreshItems.add(item)
    }

    func makePersistentMenuActionItem(
        title: String,
        action: MenuDescriptor.MenuAction,
        menu: NSMenu,
        width: CGFloat) -> NSMenuItem
    {
        let shortcut = self.shortcut(for: action)
        let shortcutText = shortcut.map { self.shortcutDisplayLabel(for: $0) }
        let item = NSMenuItem()
        item.representedObject = self.persistentMenuActionIdentifier(for: action)
        let isEnabled = action != .refresh || !self.isRefreshActionInFlight(for: menu)
        let usesCustomView = action == .refresh || self.menuCardRenderingEnabledForController

        if usesCustomView {
            let metrics = PersistentMenuActionRowMetrics.defaults
            let view = PersistentMenuActionView(
                title: title,
                systemImageName: action.systemImageName,
                shortcutText: shortcutText,
                onClick: { [weak self, weak menu] in
                    guard let self, let menu else { return }
                    self.performPersistentMenuAction(action, in: menu)
                })
            view.setEnabled(isEnabled)
            view.applySize(width: width, height: metrics.rowHeight)
            item.view = view
        }

        item.title = title
        if usesCustomView {
            self.configureCustomMenuActionItem(item, action: action)
            item.keyEquivalentModifierMask = []
        } else {
            self.configureNativeFallbackActionItem(item, action: action, shortcut: shortcut)
        }
        item.isEnabled = isEnabled
        item.toolTip = title
        return item
    }

    private func configureCustomMenuActionItem(_ item: NSMenuItem, action: MenuDescriptor.MenuAction) {
        guard action != .refresh else {
            // Refresh is handled by the custom view/menu shortcut so the tracked menu can stay open.
            item.action = nil
            item.target = nil
            return
        }

        // Keep native keyboard activation for custom Settings/About/Quit rows.
        let (selector, _) = self.selector(for: action)
        item.action = selector
        item.target = self
    }

    private func configureNativeFallbackActionItem(
        _ item: NSMenuItem,
        action: MenuDescriptor.MenuAction,
        shortcut: (key: String, modifiers: NSEvent.ModifierFlags)?)
    {
        let (selector, represented) = self.selector(for: action)
        item.action = selector
        item.target = self
        item.representedObject = represented
        if let shortcut {
            item.keyEquivalent = shortcut.key
            item.keyEquivalentModifierMask = shortcut.modifiers
        }
        if let iconName = action.systemImageName,
           let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        {
            image.isTemplate = true
            image.size = NSSize(width: 16, height: 16)
            item.image = image
        }
    }

    private func persistentMenuActionIdentifier(for action: MenuDescriptor.MenuAction) -> String {
        switch action {
        case .refresh:
            Self.persistentRefreshMenuItemID
        case .settings:
            Self.persistentActionMenuItemIDPrefix + "settings"
        case .about:
            Self.persistentActionMenuItemIDPrefix + "about"
        case .quit:
            Self.persistentActionMenuItemIDPrefix + "quit"
        default:
            Self.persistentActionMenuItemIDPrefix + "unsupported"
        }
    }

    private func performPersistentMenuAction(_ action: MenuDescriptor.MenuAction, in menu: NSMenu) {
        switch action {
        case .refresh:
            self.performPersistentRefreshAction(in: ObjectIdentifier(menu))
        case .settings:
            self.closeMenuForPersistentAction(menu)
            self.showSettingsGeneral()
        case .about:
            self.closeMenuForPersistentAction(menu)
            self.showSettingsAbout()
        case .quit:
            self.quit()
        default:
            assertionFailure("Unsupported persistent menu action: \(action)")
        }
    }

    private func closeMenuForPersistentAction(_ menu: NSMenu) {
        menu.cancelTrackingWithoutAnimation()
        self.forgetClosedMenu(menu)
    }

    private func shortcutDisplayLabel(for shortcut: (key: String, modifiers: NSEvent.ModifierFlags)) -> String {
        var label = ""
        if shortcut.modifiers.contains(.control) {
            label += "^"
        }
        if shortcut.modifiers.contains(.option) {
            label += "⌥"
        }
        if shortcut.modifiers.contains(.shift) {
            label += "⇧"
        }
        if shortcut.modifiers.contains(.command) {
            label += "⌘"
        }
        if !label.isEmpty {
            label += " "
        }
        label += shortcut.key.uppercased()
        return label
    }
}

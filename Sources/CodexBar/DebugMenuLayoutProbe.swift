import CodexBarCore
import Foundation

struct DebugMenuLayoutProbeDefaults {
    var scopeRaw: String
    var actionRaw: String
    var iconRaw: String
    var titleRaw: String
    var itemEnabled: Bool
    var iconPointSize: Double
}

enum DebugMenuLayoutProbeIconSize {
    static let defaultValue = 16.0
    static let range: ClosedRange<Double> = 10.0...22.0
    static let step = 0.5

    static func sanitized(_ value: Double) -> Double {
        min(max(value, self.range.lowerBound), self.range.upperBound)
    }
}

enum DebugMenuLayoutProbeScope: String, CaseIterable, Identifiable {
    case off
    case affectedProviders
    case allProviderMenus
    case overview
    case allMenus

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .off: "Off"
        case .affectedProviders: "Affected providers"
        case .allProviderMenus: "All provider menus"
        case .overview: "Overview only"
        case .allMenus: "All menus"
        }
    }

    func applies(provider: UsageProvider?) -> Bool {
        switch self {
        case .off:
            false
        case .affectedProviders:
            provider.map(Self.affectedProviderIDs.contains) ?? false
        case .allProviderMenus:
            provider != nil
        case .overview:
            provider == nil
        case .allMenus:
            true
        }
    }

    private static let affectedProviderIDs: Set<UsageProvider> = [
        .antigravity,
        .llmproxy,
        .litellm,
    ]
}

enum DebugMenuLayoutProbeAction: String, CaseIterable, Identifiable {
    case dashboard
    case statusPage
    case switchAccount
    case settings
    case about

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .dashboard: "Dashboard action"
        case .statusPage: "Status action"
        case .switchAccount: "Switch-account action"
        case .settings: "Settings action"
        case .about: "About action"
        }
    }

    func menuAction(provider: UsageProvider?) -> MenuDescriptor.MenuAction? {
        switch self {
        case .dashboard:
            .dashboard
        case .statusPage:
            .statusPage
        case .switchAccount:
            provider.map(MenuDescriptor.MenuAction.switchAccount)
        case .settings:
            .settings
        case .about:
            .about
        }
    }
}

enum DebugMenuLayoutProbeIcon: String, CaseIterable, Identifiable {
    case actionDefault
    case none
    case dashboard
    case chartBarHorizontalPage
    case chartLineTextClipboard
    case waveformECGTextClipboard
    case chartBarDocHorizontal
    case chartPie
    case chartLineCircle
    case speedometer
    case gauge
    case gaugeDots
    case chartLine
    case grid
    case rectangleGroup
    case statusPage
    case switchAccount
    case settings
    case refresh

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .actionDefault: "Action default"
        case .none: "No icon"
        case .dashboard: "Dashboard icon"
        case .chartBarHorizontalPage: "Bar page icon"
        case .chartLineTextClipboard: "Line clipboard icon"
        case .waveformECGTextClipboard: "ECG clipboard icon"
        case .chartBarDocHorizontal: "Bar document icon"
        case .chartPie: "Chart pie icon"
        case .chartLineCircle: "Chart circle icon"
        case .speedometer: "Speedometer icon"
        case .gauge: "Gauge icon"
        case .gaugeDots: "Gauge dots icon"
        case .chartLine: "Chart line icon"
        case .grid: "Grid icon"
        case .rectangleGroup: "Panel group icon"
        case .statusPage: "Status icon"
        case .switchAccount: "Switch-account icon"
        case .settings: "Settings icon"
        case .refresh: "Refresh icon"
        }
    }

    func systemImageName(for action: MenuDescriptor.MenuAction) -> String? {
        switch self {
        case .actionDefault:
            action.systemImageName
        case .none:
            nil
        case .dashboard:
            MenuDescriptor.MenuActionSystemImage.dashboard.rawValue
        case .chartBarHorizontalPage:
            "chart.bar.horizontal.page"
        case .chartLineTextClipboard:
            "chart.line.text.clipboard"
        case .waveformECGTextClipboard:
            "waveform.path.ecg.text.clipboard"
        case .chartBarDocHorizontal:
            "chart.bar.doc.horizontal"
        case .chartPie:
            "chart.pie"
        case .chartLineCircle:
            "chart.line.uptrend.xyaxis.circle"
        case .speedometer:
            "speedometer"
        case .gauge:
            "gauge"
        case .gaugeDots:
            "gauge.with.dots.needle.67percent"
        case .chartLine:
            "chart.line.uptrend.xyaxis"
        case .grid:
            "square.grid.2x2"
        case .rectangleGroup:
            "rectangle.3.group"
        case .statusPage:
            MenuDescriptor.MenuActionSystemImage.statusPage.rawValue
        case .switchAccount:
            MenuDescriptor.MenuActionSystemImage.switchAccount.rawValue
        case .settings:
            MenuDescriptor.MenuActionSystemImage.settings.rawValue
        case .refresh:
            MenuDescriptor.MenuActionSystemImage.refresh.rawValue
        }
    }
}

enum DebugMenuLayoutProbeTitle: String, CaseIterable, Identifiable {
    case short
    case dashboard
    case statusPage
    case addAccount
    case refresh

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .short: "X"
        case .dashboard: "Usage Dashboard"
        case .statusPage: "Status Page"
        case .addAccount: "Add Account..."
        case .refresh: "Refresh"
        }
    }

    var menuTitle: String {
        self.title
    }
}

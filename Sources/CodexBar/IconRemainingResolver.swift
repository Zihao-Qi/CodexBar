import CodexBarCore

enum IconRemainingResolver {
    private static let visibleZeroPercent = 0.0001
    private static let antigravityQuotaSummaryWindowIDPrefix = "antigravity-quota-summary-"
    private static let antigravityCompactFallbackWindowIDPrefix = "antigravity-compact-fallback-"
    private static let antigravityGeminiQuotaBucketIDPrefix = "gemini-"
    // Antigravity quota summaries currently expose exact 5-hour session and weekly buckets for the compact icon.
    private static let sessionWindowMinutes = 5 * 60
    private static let weeklyWindowMinutes = 7 * 24 * 60

    private static func codexProjection(snapshot: UsageSnapshot) -> CodexConsumerProjection {
        CodexConsumerProjection.make(
            surface: .menuBar,
            context: CodexConsumerProjection.Context(
                snapshot: snapshot,
                rawUsageError: nil,
                liveCredits: nil,
                rawCreditsError: nil,
                liveDashboard: nil,
                rawDashboardError: nil,
                dashboardAttachmentAuthorized: false,
                dashboardRequiresLogin: false,
                now: snapshot.updatedAt))
    }

    private static func codexVisibleWindows(snapshot: UsageSnapshot) -> [RateWindow] {
        let projection = self.codexProjection(snapshot: snapshot)
        return projection.visibleRateLanes.compactMap { projection.rateWindow(for: $0) }
    }

    private static func antigravityQuotaSummaryWindows(
        snapshot: UsageSnapshot)
        -> (primary: RateWindow?, secondary: RateWindow?)?
    {
        let quotaSummaryWindows = snapshot.extraRateWindows?
            .filter {
                $0.id.hasPrefix(Self.antigravityQuotaSummaryWindowIDPrefix)
            } ?? []
        guard !quotaSummaryWindows.isEmpty else { return nil }

        let geminiWindows = quotaSummaryWindows.filter(Self.isAntigravityGeminiQuotaSummaryWindow)
        // The Antigravity menu-bar icon represents Gemini quotas. If any Gemini cadence is present,
        // keep missing Gemini lanes empty instead of silently borrowing Claude + GPT quota.
        if !geminiWindows.isEmpty {
            return self.antigravityQuotaSummaryPair(in: geminiWindows.filter(\.usageKnown))
                ?? (primary: nil, secondary: nil)
        }
        return self.antigravityQuotaSummaryPair(in: quotaSummaryWindows.filter(\.usageKnown))
    }

    private static func antigravityQuotaSummaryPair(
        in windows: [NamedRateWindow])
        -> (primary: RateWindow?, secondary: RateWindow?)?
    {
        let session = self.mostConstrainedWindow(in: windows, windowMinutes: Self.sessionWindowMinutes)
        let weekly = self.mostConstrainedWindow(in: windows, windowMinutes: Self.weeklyWindowMinutes)
        guard session != nil || weekly != nil else { return nil }
        return (primary: session, secondary: weekly)
    }

    private static func isAntigravityGeminiQuotaSummaryWindow(_ window: NamedRateWindow) -> Bool {
        self.antigravityQuotaSummaryBucketID(for: window)?.hasPrefix(self.antigravityGeminiQuotaBucketIDPrefix) == true
    }

    private static func antigravityQuotaSummaryBucketID(for window: NamedRateWindow) -> String? {
        guard window.id.hasPrefix(self.antigravityQuotaSummaryWindowIDPrefix) else { return nil }
        return String(window.id.dropFirst(self.antigravityQuotaSummaryWindowIDPrefix.count))
    }

    /// Returns the highest-usage window for an exact Antigravity compact-icon cadence.
    private static func mostConstrainedWindow(in windows: [NamedRateWindow], windowMinutes: Int) -> RateWindow? {
        windows
            .filter { $0.window.windowMinutes == windowMinutes }
            .max { lhs, rhs in
                if lhs.window.usedPercent != rhs.window.usedPercent {
                    return lhs.window.usedPercent < rhs.window.usedPercent
                }
                // max(by:) keeps the right-hand element when this returns true; use `>` so the smallest id wins ties.
                return lhs.id > rhs.id
            }?
            .window
    }

    private static func antigravityLegacyVisibleWindows(snapshot: UsageSnapshot) -> [RateWindow] {
        var windows = [snapshot.primary, snapshot.secondary, snapshot.tertiary].compactMap(\.self)
        let compactFallbacks = snapshot.extraRateWindows?
            .filter {
                $0.usageKnown && $0.id.hasPrefix(Self.antigravityCompactFallbackWindowIDPrefix)
            }
            .map(\.window) ?? []
        windows.append(contentsOf: compactFallbacks)
        return windows
    }

    static func resolvedWindows(
        snapshot: UsageSnapshot,
        style: IconStyle,
        secondaryOverrideWindowID: String? = nil)
        -> (primary: RateWindow?, secondary: RateWindow?)
    {
        if style == .perplexity {
            let windows = snapshot.orderedPerplexityDisplayWindows()
            return (
                primary: windows.first,
                secondary: windows.dropFirst().first)
        }
        if style == .antigravity {
            if let windows = self.antigravityQuotaSummaryWindows(snapshot: snapshot) {
                return windows
            }
            let windows = self.antigravityLegacyVisibleWindows(snapshot: snapshot)
            return (
                primary: windows.first,
                secondary: windows.dropFirst().first)
        }
        if style == .codex {
            let windows = self.codexVisibleWindows(snapshot: snapshot)
            return (
                primary: windows.first,
                secondary: windows.dropFirst().first)
        }
        if style == .copilot,
           let secondaryOverrideWindowID,
           let extraWindow = snapshot.extraRateWindows?.first(where: { $0.id == secondaryOverrideWindowID })?.window
        {
            return (
                primary: snapshot.primary,
                secondary: extraWindow)
        }
        return (
            primary: snapshot.primary,
            secondary: snapshot.secondary)
    }

    static func resolvedRemaining(
        snapshot: UsageSnapshot,
        style: IconStyle,
        secondaryOverrideWindowID: String? = nil)
        -> (primary: Double?, secondary: Double?)
    {
        let windows = self.resolvedWindows(
            snapshot: snapshot,
            style: style,
            secondaryOverrideWindowID: secondaryOverrideWindowID)
        return (
            primary: windows.primary?.remainingPercent,
            secondary: windows.secondary?.remainingPercent)
    }

    static func resolvedPercents(
        snapshot: UsageSnapshot,
        style: IconStyle,
        showUsed: Bool,
        secondaryOverrideWindowID: String? = nil)
        -> (primary: Double?, secondary: Double?)
    {
        let windows = Self.resolvedWindows(
            snapshot: snapshot,
            style: style,
            secondaryOverrideWindowID: secondaryOverrideWindowID)
        var percents = (
            primary: showUsed ? windows.primary?.usedPercent : windows.primary?.remainingPercent,
            secondary: showUsed ? windows.secondary?.usedPercent : windows.secondary?.remainingPercent)
        if showUsed, style == .warp, let secondary = windows.secondary {
            if secondary.remainingPercent <= 0 {
                // Preserve Warp's exhausted/no-bonus layout even though used percent is 100.
                percents.secondary = 0
            } else if percents.secondary == 0 {
                // A zero fill means "lane absent" to IconRenderer; keep an unused bonus lane visible.
                percents.secondary = self.visibleZeroPercent
            }
        }
        return percents
    }
}

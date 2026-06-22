import Foundation
import Testing
@testable import CodexBarCore

struct AdminAPIUsageLocalDaySelectionTests {
    @Test
    func `OpenAI current day includes UTC bucket overlapping positive timezone morning`() throws {
        let calendar = try Self.calendar(timeZoneIdentifier: "Australia/Sydney")
        let now = try Self.date(year: 2026, month: 5, day: 18, hour: 8, timeZoneIdentifier: "Australia/Sydney")
        let staleUTCStart = try Self.date(year: 2026, month: 5, day: 16, hour: 0, timeZoneIdentifier: "UTC")
        let overlappingUTCStart = try Self.date(year: 2026, month: 5, day: 17, hour: 0, timeZoneIdentifier: "UTC")
        let usage = OpenAIAPIUsageSnapshot(
            daily: [
                OpenAIAPIUsageSnapshot.DailyBucket(
                    day: "2026-05-16",
                    startTime: staleUTCStart,
                    endTime: staleUTCStart.addingTimeInterval(86400),
                    costUSD: 9,
                    requests: 9,
                    inputTokens: 900,
                    cachedInputTokens: 90,
                    outputTokens: 90,
                    totalTokens: 990,
                    lineItems: [],
                    models: []),
                OpenAIAPIUsageSnapshot.DailyBucket(
                    day: "2026-05-17",
                    startTime: overlappingUTCStart,
                    endTime: overlappingUTCStart.addingTimeInterval(86400),
                    costUSD: 2.5,
                    requests: 3,
                    inputTokens: 200,
                    cachedInputTokens: 20,
                    outputTokens: 30,
                    totalTokens: 250,
                    lineItems: [],
                    models: []),
            ],
            updatedAt: now)

        let today = usage.summary(forLocalDayContaining: now, calendar: calendar)

        #expect(today.costUSD == 2.5)
        #expect(today.requests == 3)
        #expect(today.totalTokens == 250)
    }

    @Test
    func `Claude Admin current day includes UTC bucket overlapping positive timezone morning`() throws {
        let calendar = try Self.calendar(timeZoneIdentifier: "Australia/Sydney")
        let now = try Self.date(year: 2026, month: 5, day: 18, hour: 8, timeZoneIdentifier: "Australia/Sydney")
        let staleUTCStart = try Self.date(year: 2026, month: 5, day: 16, hour: 0, timeZoneIdentifier: "UTC")
        let overlappingUTCStart = try Self.date(year: 2026, month: 5, day: 17, hour: 0, timeZoneIdentifier: "UTC")
        let usage = ClaudeAdminAPIUsageSnapshot(
            daily: [
                ClaudeAdminAPIUsageSnapshot.DailyBucket(
                    day: "2026-05-16",
                    startTime: staleUTCStart,
                    endTime: staleUTCStart.addingTimeInterval(86400),
                    costUSD: 9,
                    inputTokens: 900,
                    cacheCreationInputTokens: 90,
                    cacheReadInputTokens: 45,
                    outputTokens: 90,
                    totalTokens: 1125,
                    costItems: [],
                    models: []),
                ClaudeAdminAPIUsageSnapshot.DailyBucket(
                    day: "2026-05-17",
                    startTime: overlappingUTCStart,
                    endTime: overlappingUTCStart.addingTimeInterval(86400),
                    costUSD: 2.5,
                    inputTokens: 200,
                    cacheCreationInputTokens: 20,
                    cacheReadInputTokens: 10,
                    outputTokens: 30,
                    totalTokens: 260,
                    costItems: [],
                    models: []),
            ],
            updatedAt: now)

        let today = usage.summary(forLocalDayContaining: now, calendar: calendar)

        #expect(today.costUSD == 2.5)
        #expect(today.inputTokens == 200)
        #expect(today.totalTokens == 260)
    }

    private static func calendar(timeZoneIdentifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        return calendar
    }

    private static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        timeZoneIdentifier: String) throws -> Date
    {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: timeZoneIdentifier)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return try #require(components.date)
    }
}

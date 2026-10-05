//
//  TradeChallengeWidget.swift
//  TradeChallengeWidget
//
//  Created by ChhunMengchhy on 30/9/26.
//

import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let challengeName: String
    let currentBalance: String
    let targetBalance: String
    let paceStatus: String
    let requiredToday: String
    let traderLevel: String
    let chartPath: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            challengeName: "10K Challenge",
            currentBalance: "$10,450.00",
            targetBalance: "$12,000",
            paceStatus: "Ahead",
            requiredToday: "+$150.00 req.",
            traderLevel: "Lvl 3 Discipline Master",
            chartPath: ""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(getEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = getEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func getEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.tradejourney.app") ?? UserDefaults.standard
        return SimpleEntry(
            date: Date(),
            challengeName: userDefaults.string(forKey: "challenge_name") ?? "No Active Challenge",
            currentBalance: userDefaults.string(forKey: "current_balance") ?? "$0.00",
            targetBalance: userDefaults.string(forKey: "target_balance") ?? "$0",
            paceStatus: userDefaults.string(forKey: "pace_status") ?? "No Data",
            requiredToday: userDefaults.string(forKey: "required_today") ?? "Create a challenge",
            traderLevel: userDefaults.string(forKey: "trader_level") ?? "Trader",
            chartPath: userDefaults.string(forKey: "chart_path") ?? ""
        )
    }
}

struct TradeChallengeWidgetEntryView : View {
    var entry: Provider.Entry

    var paceColor: Color {
        switch entry.paceStatus {
        case "Ahead":
            return Color.green
        case "Behind":
            return Color.red
        default:
            return Color.blue
        }
    }

    var isNoActiveChallenge: Bool {
        return entry.challengeName == "No Active Challenge" || entry.challengeName == "Widget Disabled"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.challengeName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(entry.traderLevel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if !isNoActiveChallenge {
                    Text(entry.paceStatus)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(paceColor.opacity(0.18))
                        .foregroundColor(paceColor)
                        .clipShape(Capsule())
                }
            }

            if !isNoActiveChallenge,
               !entry.chartPath.isEmpty,
               let uiImage = UIImage(contentsOfFile: entry.chartPath) {
                Spacer(minLength: 2)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(6)
                Spacer(minLength: 2)
            } else {
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Balance")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(entry.currentBalance)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }

            HStack {
                Text("Target: \(entry.targetBalance)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.requiredToday)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(12)
    }
}

struct TradeChallengeWidget: Widget {
    let kind: String = "TradeChallengeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TradeChallengeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Trade Journey Challenge")
        .description("Track your active trading challenge and daily target on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TradeChallengeWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        challengeName: "10K Growth Challenge",
        currentBalance: "$10,450.00",
        targetBalance: "$12,000",
        paceStatus: "Ahead",
        requiredToday: "+$150.00 req.",
        traderLevel: "Lvl 3 Discipline Master",
        chartPath: ""
    )
}

import ActivityKit
import WidgetKit
import SwiftUI

struct StatusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var expiresAt: Date
        var activities: [String]
        var district: String?
    }

    let username: String
}

struct SvobodenWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StatusActivityAttributes.self) { context in
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "hand.wave.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("Я свободен")
                        .font(.headline)
                    Spacer()
                    Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Color.accentColor)
                }
                if !context.state.activities.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(context.state.activities, id: \.self) { act in
                            Text(act)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
                if let district = context.state.district {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                        Text(district)
                            .font(.caption)
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "hand.wave.fill")
                        .foregroundStyle(Color.accentColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                        .monospacedDigit()
                        .foregroundStyle(Color.accentColor)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.activities.isEmpty {
                        Text(context.state.activities.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "hand.wave.fill")
                    .foregroundStyle(Color.accentColor)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                    .monospacedDigit()
                    .frame(maxWidth: 50)
            } minimal: {
                Image(systemName: "hand.wave.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

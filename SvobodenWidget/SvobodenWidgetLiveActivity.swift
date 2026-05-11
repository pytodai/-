import ActivityKit
import WidgetKit
import SwiftUI

private enum Brand {
    static let accent = Color(red: 1.00, green: 0.42, blue: 0.10)
    static let online = Color(red: 0.30, green: 0.85, blue: 0.40)
}

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
            lockScreen(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Brand.accent)
                        Text("СВОБОДЕН")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                        .monospacedDigit()
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(Brand.accent)
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        if !context.state.activities.isEmpty {
                            Text(context.state.activities.prefix(3).joined(separator: " · "))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        if let district = context.state.district {
                            HStack(spacing: 2) {
                                Image(systemName: "mappin").font(.system(size: 9))
                                Text(district).font(.system(size: 11))
                            }
                            .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Brand.accent)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.expiresAt,
                     countsDown: true,
                     showsHours: false)
                    .monospacedDigit()
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Brand.accent)
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Brand.accent)
            }
            .keylineTint(Brand.accent)
        }
    }

    @ViewBuilder
    private func lockScreen(context: ActivityViewContext<StatusActivityAttributes>) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Brand.accent)
                    Text("СВОБОДЕН")
                        .font(.system(size: 12, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.6))
                }

                if !context.state.activities.isEmpty {
                    Text(context.state.activities.prefix(3).joined(separator: " · "))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                } else {
                    Text("Готов встретиться")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                if let district = context.state.district {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(district)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 0) {
                Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                    .monospacedDigit()
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(Brand.accent)
                    .multilineTextAlignment(.trailing)
                Text("осталось")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

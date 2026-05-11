import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Brand
private enum Brand {
    static let coral  = Color(red: 1.00, green: 0.42, blue: 0.62)
    static let peach  = Color(red: 1.00, green: 0.55, blue: 0.26)
    static let violet = Color(red: 0.62, green: 0.48, blue: 1.00)
    static let mint   = Color(red: 0.31, green: 0.80, blue: 0.77)

    static let primary = LinearGradient(
        colors: [coral, peach],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let aurora = LinearGradient(
        colors: [violet, coral],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Attributes (must match StatusActivityAttributes in main app)
struct StatusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var expiresAt: Date
        var activities: [String]
        var district: String?
    }
    let username: String
}

// MARK: - Live Activity
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
                            .foregroundStyle(Brand.coral)
                        Text("Свободен")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                        .monospacedDigit()
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Brand.coral)
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        if !context.state.activities.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(context.state.activities, id: \.self) { act in
                                        Text(act)
                                            .font(.system(size: 11, weight: .semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(Brand.aurora.opacity(0.25)))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                        if let district = context.state.district {
                            Label(district, systemImage: "mappin.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "hand.wave.fill")
                    .foregroundStyle(Brand.coral)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.expiresAt,
                     countsDown: true,
                     showsHours: false)
                    .monospacedDigit()
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Brand.coral)
                    .frame(width: 44)
            } minimal: {
                ZStack {
                    Circle().fill(Brand.primary)
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .keylineTint(Brand.coral)
        }
    }

    @ViewBuilder
    private func lockScreen(context: ActivityViewContext<StatusActivityAttributes>) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Brand.primary)
                    .frame(width: 52, height: 52)
                    .shadow(color: Brand.coral.opacity(0.4), radius: 8, y: 4)
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Ты свободен")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))

                if !context.state.activities.isEmpty {
                    Text(context.state.activities.prefix(3).joined(separator: " · "))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                } else {
                    Text("Готов встретиться")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                if let district = context.state.district {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                        Text(district)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.white.opacity(0.55))
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                    .monospacedDigit()
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Brand.coral)
                    .multilineTextAlignment(.trailing)
                Text("осталось")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

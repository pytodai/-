import SwiftUI

struct StatusCardView: View {
    let status: UserStatus
    let onClear: () async -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, status.expiresAt.timeIntervalSince(context.date))
            let hours   = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            let seconds = Int(remaining) % 60
            let urgent  = remaining < 600

            VStack(alignment: .leading, spacing: Theme.s4) {
                HStack(spacing: Theme.s2) {
                    Circle()
                        .fill(Theme.mint)
                        .frame(width: 10, height: 10)
                        .shadow(color: Theme.mint.opacity(0.6), radius: 6)
                    Text("Ты свободен")
                        .font(.bodyStrong)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        Task { await onClear() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                }

                Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(urgent ? AnyShapeStyle(Color.red) : AnyShapeStyle(Theme.sunsetGradient))
                    .contentTransition(.numericText())

                if !status.activities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.s2) {
                            ForEach(status.activities, id: \.self) { act in
                                let activity = Activity(rawValue: act)
                                HStack(spacing: 6) {
                                    if let activity {
                                        Image(systemName: activity.icon)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    Text(act)
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, Theme.s3)
                                .padding(.vertical, 8)
                                .background(Theme.auroraGradient)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                if let district = status.district {
                    Label(district, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .glassCard(padding: Theme.s5)
        }
    }
}

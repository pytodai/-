import SwiftUI

struct StatusCardView: View {
    let status: UserStatus
    let onClear: () async -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, status.expiresAt.timeIntervalSince(context.date))
            let h = Int(remaining) / 3600
            let m = (Int(remaining) % 3600) / 60
            let s = Int(remaining) % 60
            let urgent = remaining < 600

            VStack(alignment: .leading, spacing: Theme.s4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.online)
                        .frame(width: 8, height: 8)
                    Text("СВОБОДЕН")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Button {
                        Task { await onClear() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(IconButtonStyle())
                }

                Text(String(format: "%02d:%02d:%02d", h, m, s))
                    .font(.system(size: 56, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(urgent ? Theme.danger : Color.primary)
                    .contentTransition(.numericText())

                if !status.activities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(status.activities, id: \.self) { act in
                                let activity = Activity(rawValue: act)
                                HStack(spacing: 6) {
                                    if let activity {
                                        Image(systemName: activity.icon)
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    Text(act)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.rSm)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                }

                if let district = status.district {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11, weight: .bold))
                        Text(district)
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Theme.muted)
                }
            }
            .card(padding: Theme.s5)
        }
    }
}

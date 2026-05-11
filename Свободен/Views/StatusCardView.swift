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

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill").foregroundStyle(.green)
                    Text("Ты свободен").font(.headline)
                    Spacer()
                    Button(role: .destructive) {
                        Task { await onClear() }
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }

                Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                    .foregroundStyle(remaining < 600 ? .red : .primary)

                if !status.activities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(status.activities, id: \.self) { act in
                                HStack(spacing: 4) {
                                    if let activity = Activity(rawValue: act) {
                                        Image(systemName: activity.icon)
                                    }
                                    Text(act)
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }

                if let district = status.district {
                    Label(district, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

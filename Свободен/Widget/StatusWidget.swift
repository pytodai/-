import WidgetKit
import SwiftUI

struct StatusEntry: TimelineEntry {
    let date: Date
    let status: WidgetStatus?
}

struct WidgetStatus {
    let expiresAt: Date
    let activities: [String]
    let district: String?
}

struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: .now, status: WidgetStatus(
            expiresAt: Date().addingTimeInterval(3600),
            activities: ["кафе"],
            district: "Арбат"
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        Task {
            var entry = StatusEntry(date: .now, status: nil)
            if let token = KeychainService.loadToken(),
               let status = try? await APIClient.shared.getStatus() {
                _ = token
                entry = StatusEntry(date: .now, status: WidgetStatus(
                    expiresAt: status.expiresAt,
                    activities: status.activities,
                    district: status.district
                ))
            }
            let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }
}

struct StatusWidgetEntryView: View {
    var entry: StatusEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let status = entry.status {
            activeView(status: status)
        } else {
            inactiveView
        }
    }

    @ViewBuilder
    private func activeView(status: WidgetStatus) -> some View {
        let remaining = max(0, status.expiresAt.timeIntervalSince(entry.date))
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("Свободен").font(.caption.bold()).foregroundStyle(.green)
            }
            Text(String(format: "%02d:%02d", h, m))
                .font(.system(.title2, design: .monospaced).bold())
            if !status.activities.isEmpty {
                Text(status.activities.prefix(2).joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .containerBackground(.regularMaterial, for: .widget)
    }

    private var inactiveView: some View {
        VStack(spacing: 4) {
            Image(systemName: "hand.wave").font(.title2).foregroundStyle(.secondary)
            Text("Не свободен").font(.caption).foregroundStyle(.secondary)
        }
        .containerBackground(.regularMaterial, for: .widget)
    }
}

// NOTE: Add this to a separate Widget Extension target in Xcode.
// File → New → Target → Widget Extension, name "СвободенWidget"
// Then move this file to that target and add @main back.
struct StatusWidget: Widget {
    let kind = "StatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusProvider()) { entry in
            StatusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Свободен")
        .description("Показывает твой текущий статус")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

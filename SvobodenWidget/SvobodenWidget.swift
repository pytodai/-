import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SvobodenEntry {
        SvobodenEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SvobodenEntry) -> ()) {
        completion(SvobodenEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SvobodenEntry>) -> ()) {
        let timeline = Timeline(entries: [SvobodenEntry(date: Date())], policy: .atEnd)
        completion(timeline)
    }
}

struct SvobodenEntry: TimelineEntry {
    let date: Date
}

struct SvobodenWidgetEntryView: View {
    var entry: SvobodenEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().stroke(Color.accentColor, lineWidth: 2)
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentColor)
            }
        case .accessoryRectangular:
            HStack(spacing: 6) {
                Image(systemName: "hand.wave.fill")
                Text("Я свободен!").font(.headline)
            }
        default:
            VStack(spacing: 8) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
                Text("Я свободен!")
                    .font(.headline)
                Text("Открыть приложение")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SvobodenWidget: Widget {
    let kind: String = "SvobodenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SvobodenWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Свободен")
        .description("Быстрый доступ к статусу")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    SvobodenWidget()
} timeline: {
    SvobodenEntry(date: .now)
}

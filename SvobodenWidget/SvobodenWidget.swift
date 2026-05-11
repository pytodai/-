import WidgetKit
import SwiftUI

private enum Brand {
    static let accent = Color(red: 1.00, green: 0.42, blue: 0.10)
}

struct SvobodenEntry: TimelineEntry { let date: Date }

struct SvobodenProvider: TimelineProvider {
    func placeholder(in context: Context) -> SvobodenEntry { SvobodenEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (SvobodenEntry) -> Void) {
        completion(SvobodenEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SvobodenEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [SvobodenEntry(date: .now)], policy: .after(next)))
    }
}

struct SvobodenWidgetEntryView: View {
    var entry: SvobodenEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Circle().stroke(Color.white, lineWidth: 2).padding(6)
                Image(systemName: "circle.fill")
                    .font(.system(size: 18, weight: .black))
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 16, weight: .black))
                VStack(alignment: .leading, spacing: 1) {
                    Text("СВОБОДЕН")
                        .font(.system(size: 14, weight: .black))
                        .tracking(1.5)
                    Text("Готов встретиться?")
                        .font(.system(size: 11))
                        .opacity(0.7)
                }
                Spacer()
            }
        case .systemMedium:
            HStack(spacing: 16) {
                badge(size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("СВОБОДЕН")
                        .font(.system(size: 22, weight: .black))
                        .tracking(2)
                    Rectangle()
                        .fill(Brand.accent)
                        .frame(width: 28, height: 2)
                    Text("Готов встретиться? Нажми.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        default:
            VStack(spacing: 10) {
                badge(size: 58)
                Text("СВОБОДЕН")
                    .font(.system(size: 16, weight: .black))
                    .tracking(1.5)
            }
        }
    }

    private func badge(size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Brand.accent)
            Image(systemName: "circle.fill")
                .font(.system(size: size * 0.32, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct SvobodenWidget: Widget {
    let kind: String = "SvobodenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SvobodenProvider()) { entry in
            SvobodenWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Свободен")
        .description("Быстрый доступ — нажми и установи статус")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    SvobodenWidget()
} timeline: {
    SvobodenEntry(date: .now)
}

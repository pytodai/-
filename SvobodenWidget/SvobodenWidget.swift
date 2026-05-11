import WidgetKit
import SwiftUI

// MARK: - Brand colors (duplicated; widget target can't import main app theme)
private enum Brand {
    static let coral  = Color(red: 1.00, green: 0.42, blue: 0.62)
    static let peach  = Color(red: 1.00, green: 0.55, blue: 0.26)
    static let violet = Color(red: 0.62, green: 0.48, blue: 1.00)
    static let sun    = Color(red: 1.00, green: 0.78, blue: 0.28)

    static let primary = LinearGradient(
        colors: [coral, peach],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let sunset = LinearGradient(
        colors: [violet, coral, peach, sun],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Timeline
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

// MARK: - View
struct SvobodenWidgetEntryView: View {
    var entry: SvobodenEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 18, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Свободен")
                        .font(.system(size: 14, weight: .bold))
                    Text("Дай знать друзьям")
                        .font(.system(size: 11))
                        .opacity(0.7)
                }
                Spacer()
            }
        case .systemMedium:
            HStack(spacing: 16) {
                bigBadge(size: 78, iconSize: 36)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Свободен?")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Brand.sunset)
                    Text("Одно нажатие — и друзья знают, что ты готов встретиться")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
        default: // systemSmall
            VStack(spacing: 10) {
                bigBadge(size: 64, iconSize: 28)
                Text("Я свободен!")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.sunset)
            }
        }
    }

    private func bigBadge(size: CGFloat, iconSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Brand.primary)
                .shadow(color: Brand.coral.opacity(0.45), radius: 12, y: 6)
            Image(systemName: "hand.wave.fill")
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Widget
struct SvobodenWidget: Widget {
    let kind: String = "SvobodenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SvobodenProvider()) { entry in
            SvobodenWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Brand.violet.opacity(0.08),
                            Brand.coral.opacity(0.06)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
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

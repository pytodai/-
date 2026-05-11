import AppIntents
import Foundation

struct SetFreeStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Я свободен"
    static var description = IntentDescription("Установить статус свободен на указанное время")

    @Parameter(title: "Часы", default: 2)
    var hours: Int

    @Parameter(title: "Активность", default: "кафе")
    var activity: String

    static var parameterSummary: some ParameterSummary {
        Summary("Свободен на \(\.$hours) ч, \(\.$activity)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let req = SetStatusRequest(
            durationMinutes: hours * 60,
            activities: [activity],
            lat: nil,
            lon: nil
        )
        _ = try await APIClient.shared.setStatus(req)
        return .result(dialog: "Статус установлен: свободен на \(hours) ч")
    }
}

struct ClearStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Очистить статус"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await APIClient.shared.deleteStatus()
        return .result(dialog: "Статус очищен")
    }
}

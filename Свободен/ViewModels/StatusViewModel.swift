import Foundation
import CoreLocation

@Observable
@MainActor
final class StatusViewModel {
    var selectedDuration: DurationOption = .threeHours
    var customDate: Date = Date.now.addingTimeInterval(3600)
    var selectedActivities: Set<Activity> = []
    var geoEnabled = false
    var isLoading = false
    var errorMessage: String? = nil

    private let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    func setStatus(appVM: AppViewModel) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var lat: Double? = nil
        var lon: Double? = nil

        if geoEnabled {
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestPermission()
            }
            if locationService.authorizationStatus == .authorizedWhenInUse ||
               locationService.authorizationStatus == .authorizedAlways {
                if let loc = try? await locationService.currentLocation() {
                    lat = loc.coordinate.latitude
                    lon = loc.coordinate.longitude
                }
            }
        }

        let minutes: Int
        if case .custom(let date) = selectedDuration {
            minutes = DurationOption.custom(date).durationMinutes()
        } else {
            minutes = selectedDuration.durationMinutes()
        }

        let req = SetStatusRequest(
            durationMinutes: minutes,
            activities: selectedActivities.map(\.rawValue),
            lat: lat,
            lon: lon
        )

        do {
            let status = try await APIClient.shared.setStatus(req)
            appVM.currentStatus = status
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearStatus(appVM: AppViewModel) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await APIClient.shared.deleteStatus()
            appVM.currentStatus = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

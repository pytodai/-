import SwiftUI

struct SetStatusSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @Bindable var statusVM: StatusViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Как долго?").font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(DurationOption.allCases) { option in
                                    DurationChip(label: option.label,
                                                 isSelected: selectedDurationMatches(option)) {
                                        statusVM.selectedDuration = option
                                    }
                                }
                                DurationChip(label: "точное время",
                                             isSelected: {
                                                 if case .custom = statusVM.selectedDuration { return true }
                                                 return false
                                             }()) {
                                    statusVM.selectedDuration = .custom(statusVM.customDate)
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        if case .custom = statusVM.selectedDuration {
                            DatePicker("До", selection: $statusVM.customDate,
                                       in: Date.now...,
                                       displayedComponents: [.hourAndMinute, .date])
                                .datePickerStyle(.compact)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Чем займёшься?").font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                            ForEach(Activity.allCases) { activity in
                                ActivityChip(
                                    activity: activity,
                                    isSelected: statusVM.selectedActivities.contains(activity)
                                ) {
                                    if statusVM.selectedActivities.contains(activity) {
                                        statusVM.selectedActivities.remove(activity)
                                    } else {
                                        statusVM.selectedActivities.insert(activity)
                                    }
                                }
                            }
                        }
                    }

                    Toggle(isOn: $statusVM.geoEnabled) {
                        Label("Поделиться районом", systemImage: "location.fill")
                            .font(.subheadline)
                    }

                    if let error = statusVM.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Я свободен")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await statusVM.setStatus(appVM: appVM)
                            dismiss()
                        }
                    } label: {
                        if statusVM.isLoading { ProgressView() }
                        else { Text("Готово").bold() }
                    }
                    .disabled(statusVM.isLoading)
                }
            }
        }
    }

    private func selectedDurationMatches(_ option: DurationOption) -> Bool {
        switch (statusVM.selectedDuration, option) {
        case (.oneHour, .oneHour), (.threeHours, .threeHours), (.tillEvening, .tillEvening):
            return true
        default:
            return false
        }
    }
}

private struct DurationChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

private struct ActivityChip: View {
    let activity: Activity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: activity.icon)
                Text(activity.rawValue)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

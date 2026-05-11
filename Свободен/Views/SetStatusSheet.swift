import SwiftUI

struct SetStatusSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @Bindable var statusVM: StatusViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.s5) {

                    section(title: "ДЛИТЕЛЬНОСТЬ") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.s2) {
                                ForEach(DurationOption.allCases) { option in
                                    DurationChip(label: option.label,
                                                 isSelected: matches(option)) {
                                        Haptics.tap()
                                        statusVM.selectedDuration = option
                                    }
                                }
                                DurationChip(label: "точное время",
                                             isSelected: isCustom) {
                                    Haptics.tap()
                                    statusVM.selectedDuration = .custom(statusVM.customDate)
                                }
                            }
                            .padding(.horizontal, 1)
                        }

                        if isCustom {
                            DatePicker("До",
                                       selection: $statusVM.customDate,
                                       in: Date.now...,
                                       displayedComponents: [.hourAndMinute, .date])
                                .datePickerStyle(.compact)
                                .tint(Theme.accent)
                        }
                    }

                    section(title: "АКТИВНОСТИ") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Theme.s2)],
                                  spacing: Theme.s2) {
                            ForEach(Activity.allCases) { activity in
                                ActivityChip(
                                    activity: activity,
                                    isSelected: statusVM.selectedActivities.contains(activity)
                                ) {
                                    Haptics.soft()
                                    if statusVM.selectedActivities.contains(activity) {
                                        statusVM.selectedActivities.remove(activity)
                                    } else {
                                        statusVM.selectedActivities.insert(activity)
                                    }
                                }
                            }
                        }
                    }

                    section(title: "ЛОКАЦИЯ") {
                        Toggle(isOn: $statusVM.geoEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Делиться районом")
                                    .font(.bodyStrong)
                                Text("Друзья увидят, где ты примерно")
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        .tint(Theme.accent)
                    }

                    if let error = statusVM.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Theme.danger)
                    }

                    Button {
                        Haptics.success()
                        Task {
                            await statusVM.setStatus(appVM: appVM)
                            dismiss()
                        }
                    } label: {
                        if statusVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Готово")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(statusVM.isLoading)
                    .padding(.top, Theme.s2)
                }
                .padding(Theme.s4)
            }
            .navigationTitle("Новый статус")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.soft()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                    .buttonStyle(IconButtonStyle())
                }
            }
        }
    }

    private var isCustom: Bool {
        if case .custom = statusVM.selectedDuration { return true }
        return false
    }

    private func matches(_ option: DurationOption) -> Bool {
        switch (statusVM.selectedDuration, option) {
        case (.oneHour, .oneHour), (.threeHours, .threeHours), (.tillEvening, .tillEvening):
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Theme.muted)
            content()
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
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, Theme.s4)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? Color.white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: Theme.rSm)
                        .fill(isSelected ? Theme.accent : Theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.rSm)
                        .stroke(isSelected ? Color.clear : Theme.border, lineWidth: 1)
                )
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
                    .font(.system(size: 13, weight: .semibold))
                Text(activity.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? Color.white : .primary)
            .background(
                RoundedRectangle(cornerRadius: Theme.rSm)
                    .fill(isSelected ? Theme.accent : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rSm)
                    .stroke(isSelected ? Color.clear : Theme.border, lineWidth: 1)
            )
        }
    }
}

import SwiftUI

struct SetStatusSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @Bindable var statusVM: StatusViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground().opacity(0.6)

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.s5) {

                        section(title: "Как долго?", icon: "clock.fill") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.s2) {
                                    ForEach(DurationOption.allCases) { option in
                                        DurationChip(label: option.label,
                                                     isSelected: selectedDurationMatches(option)) {
                                            Haptics.tap()
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                statusVM.selectedDuration = option
                                            }
                                        }
                                    }
                                    DurationChip(label: "точное время",
                                                 isSelected: isCustom) {
                                        Haptics.tap()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            statusVM.selectedDuration = .custom(statusVM.customDate)
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                            }

                            if isCustom {
                                DatePicker("До",
                                           selection: $statusVM.customDate,
                                           in: Date.now...,
                                           displayedComponents: [.hourAndMinute, .date])
                                    .datePickerStyle(.compact)
                                    .tint(Theme.coral)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }

                        section(title: "Чем займёшься?", icon: "sparkles") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: Theme.s2)], spacing: Theme.s2) {
                                ForEach(Activity.allCases) { activity in
                                    ActivityChip(
                                        activity: activity,
                                        isSelected: statusVM.selectedActivities.contains(activity)
                                    ) {
                                        Haptics.soft()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                            if statusVM.selectedActivities.contains(activity) {
                                                statusVM.selectedActivities.remove(activity)
                                            } else {
                                                statusVM.selectedActivities.insert(activity)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        section(title: "Локация", icon: "location.fill") {
                            Toggle(isOn: $statusVM.geoEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Поделиться районом")
                                        .font(.bodyStrong)
                                    Text("Друзья увидят примерно где ты")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(Theme.coral)
                        }

                        if let error = statusVM.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
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
                                HStack(spacing: 8) {
                                    Image(systemName: "hand.wave.fill")
                                    Text("Я свободен!")
                                }
                            }
                        }
                        .buttonStyle(GradientButtonStyle())
                        .disabled(statusVM.isLoading)
                        .padding(.top, Theme.s2)
                    }
                    .padding(Theme.s4)
                }
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
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Circle().fill(Color.primary.opacity(0.08)))
                    }
                }
            }
        }
    }

    private var isCustom: Bool {
        if case .custom = statusVM.selectedDuration { return true }
        return false
    }

    private func selectedDurationMatches(_ option: DurationOption) -> Bool {
        switch (statusVM.selectedDuration, option) {
        case (.oneHour, .oneHour), (.threeHours, .threeHours), (.tillEvening, .tillEvening):
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.coral)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.titleStrong)
            }
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
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, Theme.s4)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(Theme.primaryGradient)
                                .shadow(color: Theme.coral.opacity(0.35), radius: 10, x: 0, y: 5)
                        } else {
                            Capsule().fill(Theme.card)
                                .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
                        }
                    }
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
                Text(activity.rawValue)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                            .fill(Theme.auroraGradient)
                            .shadow(color: Theme.coral.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                            .fill(Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                }
            )
        }
        .scaleEffect(isSelected ? 1.03 : 1.0)
    }
}

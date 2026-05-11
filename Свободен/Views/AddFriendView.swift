import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    var friendsVM: FriendsViewModel
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.s4) {
                Spacer(minLength: Theme.s5)

                if success {
                    VStack(spacing: Theme.s3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .stroke(Theme.accent, lineWidth: 2)
                            )
                        Text("Заявка отправлена")
                            .font(.titleStrong)
                        Text("Жди, когда друг примет")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }
                } else {
                    VStack(spacing: Theme.s2) {
                        Text("Добавить друга")
                            .font(.titleStrong)
                        Text("Введи логин")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.bottom, Theme.s2)

                    HStack(spacing: 6) {
                        Text("@")
                            .font(.bodyStrong)
                            .foregroundStyle(Theme.muted)
                        TextField("login", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.bodyStrong)
                            .focused($isFocused)
                    }
                    .padding(.horizontal, Theme.s4)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                            .fill(Theme.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                            .stroke(isFocused ? Theme.accent : Theme.border,
                                    lineWidth: isFocused ? 1.5 : 1)
                    )
                    .padding(.horizontal, Theme.s5)

                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Theme.danger)
                    }

                    Button {
                        Haptics.tap()
                        isFocused = false
                        Task { await send() }
                    } label: {
                        if isLoading { ProgressView().tint(.white) }
                        else { Text("Отправить заявку") }
                    }
                    .buttonStyle(PrimaryButtonStyle(enabled: !username.isEmpty))
                    .disabled(username.isEmpty || isLoading)
                    .padding(.horizontal, Theme.s5)
                }

                Spacer()
            }
            .animation(.easeOut(duration: 0.2), value: success)
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
            .onAppear { isFocused = true }
        }
    }

    private func send() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await friendsVM.sendRequest(username: username)
            Haptics.success()
            success = true
        } catch {
            Haptics.warning()
            errorMessage = error.localizedDescription
        }
    }
}

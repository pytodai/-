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
            ZStack {
                AuroraBackground().opacity(0.6)

                VStack(spacing: Theme.s5) {
                    Spacer(minLength: 20)

                    ZStack {
                        Circle()
                            .fill(Theme.auroraGradient.opacity(0.2))
                            .frame(width: 130, height: 130)
                            .blur(radius: 8)
                        Circle()
                            .fill(Theme.primaryGradient)
                            .frame(width: 100, height: 100)
                            .shadow(color: Theme.coral.opacity(0.4), radius: 18, x: 0, y: 10)
                        Image(systemName: success ? "checkmark" : "person.badge.plus")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }

                    if success {
                        VStack(spacing: Theme.s2) {
                            Text("Заявка отправлена!")
                                .font(.titleStrong)
                            Text("Жди, когда друг примет")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        VStack(spacing: Theme.s2) {
                            Text("Добавить друга")
                                .font(.titleStrong)
                            Text("Введи логин")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: Theme.s3) {
                            Text("@")
                                .font(.bodyStrong)
                                .foregroundStyle(Theme.coral)
                            TextField("login", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.bodyStrong)
                                .focused($isFocused)
                        }
                        .padding(.horizontal, Theme.s4)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                                .fill(Theme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                                .stroke(isFocused ? Theme.coral.opacity(0.6) : Theme.border,
                                        lineWidth: isFocused ? 1.5 : 1)
                        )
                        .padding(.horizontal, Theme.s5)

                        if let error = errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Haptics.tap()
                            isFocused = false
                            Task { await send() }
                        } label: {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Отправить заявку", systemImage: "paperplane.fill")
                            }
                        }
                        .buttonStyle(GradientButtonStyle())
                        .disabled(username.isEmpty || isLoading)
                        .opacity(username.isEmpty ? 0.55 : 1)
                        .padding(.horizontal, Theme.s5)
                    }

                    Spacer()
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: success)
            }
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

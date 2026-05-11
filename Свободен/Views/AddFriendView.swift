import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    var friendsVM: FriendsViewModel
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentColor)
                    Text("Добавить друга")
                        .font(.title2.bold())
                    Text("Введите логин")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if success {
                    Label("Заявка отправлена!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                } else {
                    VStack(spacing: 12) {
                        TextField("логин", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 32)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task { await send() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Отправить заявку").font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(username.isEmpty || isLoading)
                        .padding(.horizontal, 32)
                    }
                }

                Spacer()
            }
            .navigationTitle("Добавить друга")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func send() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await friendsVM.sendRequest(username: username)
            success = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

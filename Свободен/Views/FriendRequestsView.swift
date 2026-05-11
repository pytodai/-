import SwiftUI

struct FriendRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    var friendsVM: FriendsViewModel

    var body: some View {
        NavigationStack {
            Group {
                if friendsVM.pendingRequests.isEmpty {
                    VStack(spacing: Theme.s3) {
                        Image(systemName: "tray")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(Theme.muted)
                        Text("Нет заявок")
                            .font(.titleStrong)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: Theme.s2) {
                            ForEach(friendsVM.pendingRequests) { request in
                                requestRow(request)
                            }
                        }
                        .padding(Theme.s4)
                    }
                }
            }
            .navigationTitle("Заявки")
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

    private func requestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: Theme.s3) {
            Circle()
                .fill(Theme.card)
                .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(request.fromUsername.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("@" + request.fromUsername)
                    .font(.bodyStrong)
                Text("хочет добавить тебя")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            HStack(spacing: Theme.s2) {
                Button {
                    Haptics.success()
                    Task { await friendsVM.accept(request: request) }
                } label: {
                    Text("Принять")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(RoundedRectangle(cornerRadius: Theme.rSm).fill(Theme.accent))
                }
                .buttonStyle(IconButtonStyle())

                Button {
                    Haptics.warning()
                    Task { await friendsVM.decline(request: request) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.rSm)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(IconButtonStyle())
            }
        }
        .card(padding: Theme.s3)
    }
}

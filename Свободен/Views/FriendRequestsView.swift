import SwiftUI

struct FriendRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    var friendsVM: FriendsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground().opacity(0.5)

                if friendsVM.pendingRequests.isEmpty {
                    VStack(spacing: Theme.s3) {
                        ZStack {
                            Circle()
                                .fill(Theme.auroraGradient.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundStyle(Theme.sunsetGradient)
                        }
                        Text("Нет заявок")
                            .font(.titleStrong)
                        Text("Новые заявки появятся здесь")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: Theme.s3) {
                            ForEach(friendsVM.pendingRequests) { request in
                                requestRow(request)
                                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                            }
                        }
                        .padding(Theme.s4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75),
                                   value: friendsVM.pendingRequests.map(\.id))
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
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Circle().fill(Color.primary.opacity(0.08)))
                    }
                }
            }
        }
    }

    private func requestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: Theme.s3) {
            ZStack {
                Circle()
                    .fill(Theme.auroraGradient)
                    .frame(width: 48, height: 48)
                Text(String(request.fromUsername.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("@" + request.fromUsername)
                    .font(.bodyStrong)
                Text("хочет добавить тебя")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: Theme.s2) {
                Button {
                    Haptics.success()
                    Task { await friendsVM.accept(request: request) }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Theme.mint))
                }

                Button {
                    Haptics.warning()
                    Task { await friendsVM.decline(request: request) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
            }
        }
        .glassCard(padding: Theme.s3)
    }
}

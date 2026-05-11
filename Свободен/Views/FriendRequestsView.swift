import SwiftUI

struct FriendRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    var friendsVM: FriendsViewModel

    var body: some View {
        NavigationStack {
            Group {
                if friendsVM.pendingRequests.isEmpty {
                    ContentUnavailableView(
                        "Нет заявок",
                        systemImage: "person.badge.plus",
                        description: Text("Новые заявки появятся здесь")
                    )
                } else {
                    List(friendsVM.pendingRequests) { request in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(request.fromPhone)
                                    .font(.body.bold())
                                Text("Хочет добавить вас в друзья")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 12) {
                                Button {
                                    Task { await friendsVM.accept(request: request) }
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.green)
                                }
                                Button {
                                    Task { await friendsVM.decline(request: request) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Заявки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

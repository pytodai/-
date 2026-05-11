import SwiftUI

struct FriendsView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var friendsVM: FriendsViewModel
    @State private var showAddFriend = false
    @State private var showRequests = false

    init(ws: WebSocketService) {
        _friendsVM = State(initialValue: FriendsViewModel(ws: ws))
    }

    var body: some View {
        NavigationStack {
            List {
                if !friendsVM.pendingRequests.isEmpty {
                    Section {
                        Button {
                            showRequests = true
                        } label: {
                            Label("Заявки в друзья (\(friendsVM.pendingRequests.count))", systemImage: "person.badge.plus")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }

                if friendsVM.friends.isEmpty && !friendsVM.isLoading {
                    Section {
                        ContentUnavailableView(
                            "Нет друзей",
                            systemImage: "person.2.slash",
                            description: Text("Добавьте друзей по номеру телефона")
                        )
                    }
                } else {
                    Section("Друзья") {
                        ForEach(friendsVM.friends) { friend in
                            FriendRowView(friend: friend)
                        }
                        .onDelete { offsets in
                            for i in offsets {
                                Task { await friendsVM.removeFriend(friendsVM.friends[i]) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Друзья")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView(friendsVM: friendsVM)
            }
            .sheet(isPresented: $showRequests) {
                FriendRequestsView(friendsVM: friendsVM)
            }
            .refreshable {
                await friendsVM.load()
            }
            .task {
                await friendsVM.load()
            }
        }
    }
}

struct FriendRowView: View {
    let friend: Friend

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(friend.hasActiveStatus ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 10, height: 10)
                Text("@" + friend.username)
                    .font(.body)
                Spacer()
            }

            if friend.hasActiveStatus, let expiresAt = friend.expiresAt {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let remaining = max(0, expiresAt.timeIntervalSince(ctx.date))
                    let h = Int(remaining) / 3600
                    let m = (Int(remaining) % 3600) / 60
                    let s = Int(remaining) % 60
                    HStack(spacing: 6) {
                        Text(String(format: "%02d:%02d:%02d", h, m, s))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.green)

                        if let activities = friend.activities, !activities.isEmpty {
                            Text(activities.prefix(3).joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let district = friend.district {
                            Label(district, systemImage: "mappin.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

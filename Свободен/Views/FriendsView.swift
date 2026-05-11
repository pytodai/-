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
            ScrollView {
                VStack(spacing: Theme.s3) {
                    if !friendsVM.pendingRequests.isEmpty {
                        requestsBanner
                            .padding(.horizontal, Theme.s4)
                            .padding(.top, Theme.s2)
                    }

                    if friendsVM.friends.isEmpty && !friendsVM.isLoading {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: Theme.s2) {
                            ForEach(friendsVM.friends) { friend in
                                FriendRowView(friend: friend)
                                    .padding(.horizontal, Theme.s4)
                            }
                        }
                        .padding(.top, Theme.s2)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: friendsVM.friends.map(\.id))
            }
            .navigationTitle("Друзья")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showAddFriend = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(IconButtonStyle())
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView(friendsVM: friendsVM)
            }
            .sheet(isPresented: $showRequests) {
                FriendRequestsView(friendsVM: friendsVM)
            }
            .refreshable { await friendsVM.load() }
            .task { await friendsVM.load() }
        }
    }

    private var requestsBanner: some View {
        Button {
            Haptics.tap()
            showRequests = true
        } label: {
            HStack(spacing: Theme.s3) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .fill(Theme.accent.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Заявки в друзья")
                        .font(.bodyStrong)
                        .foregroundStyle(.primary)
                    Text("\(friendsVM.pendingRequests.count) ожидает ответа")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.muted)
            }
            .card(padding: Theme.s3)
        }
        .buttonStyle(IconButtonStyle())
    }

    private var emptyState: some View {
        VStack(spacing: Theme.s3) {
            Image(systemName: "person.2")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.muted)
            Text("Нет друзей")
                .font(.titleStrong)
            Text("Добавь друзей по их логину")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
            Button {
                Haptics.tap()
                showAddFriend = true
            } label: {
                Text("Добавить друга")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, Theme.s3)
        }
    }
}

struct FriendRowView: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: Theme.s3) {
            avatar

            VStack(alignment: .leading, spacing: 3) {
                Text("@" + friend.username)
                    .font(.bodyStrong)

                if friend.hasActiveStatus, let expiresAt = friend.expiresAt {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        let remaining = max(0, expiresAt.timeIntervalSince(ctx.date))
                        let h = Int(remaining) / 3600
                        let m = (Int(remaining) % 3600) / 60
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(h > 0 ? "\(h)ч \(m)м" : "\(m)м")
                                    .monospacedDigit()
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.online)

                            if let activities = friend.activities, !activities.isEmpty {
                                Text(activities.prefix(2).joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                                    .lineLimit(1)
                            }
                        }
                    }
                } else {
                    Text("офлайн")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }

            Spacer()

            if let district = friend.district, friend.hasActiveStatus {
                HStack(spacing: 3) {
                    Image(systemName: "mappin")
                    Text(district)
                }
                .font(.caption2)
                .foregroundStyle(Theme.muted)
            }
        }
        .padding(.vertical, Theme.s3)
        .padding(.horizontal, Theme.s3)
        .background(
            RoundedRectangle(cornerRadius: Theme.rLg, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rLg, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(Theme.card)
                .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(friend.username.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                )

            if friend.hasActiveStatus {
                Circle()
                    .fill(Theme.online)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
            }
        }
    }
}

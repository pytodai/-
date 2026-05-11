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
            ZStack {
                AuroraBackground().opacity(0.5)

                ScrollView {
                    VStack(spacing: Theme.s4) {
                        if !friendsVM.pendingRequests.isEmpty {
                            requestsBanner
                                .padding(.horizontal, Theme.s4)
                                .padding(.top, Theme.s2)
                        }

                        if friendsVM.friends.isEmpty && !friendsVM.isLoading {
                            emptyState
                                .padding(.top, 80)
                        } else {
                            LazyVStack(spacing: Theme.s3) {
                                ForEach(friendsVM.friends) { friend in
                                    FriendRowView(friend: friend)
                                        .padding(.horizontal, Theme.s4)
                                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                                }
                            }
                            .padding(.top, Theme.s2)
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: friendsVM.friends.map(\.id))
                }
            }
            .navigationTitle("Друзья")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(Theme.primaryGradient))
                            .shadow(color: Theme.coral.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
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
                ZStack {
                    Circle().fill(Theme.auroraGradient).frame(width: 44, height: 44)
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Заявки в друзья")
                        .font(.bodyStrong)
                        .foregroundStyle(.primary)
                    Text("\(friendsVM.pendingRequests.count) ожидает ответа")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .glassCard(padding: Theme.s3)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private var emptyState: some View {
        VStack(spacing: Theme.s4) {
            ZStack {
                Circle()
                    .fill(Theme.auroraGradient.opacity(0.18))
                    .frame(width: 110, height: 110)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.sunsetGradient)
            }
            Text("Пока нет друзей")
                .font(.titleStrong)
            Text("Добавь друзей по их логину\nчтобы видеть когда они свободны")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Haptics.tap()
                showAddFriend = true
            } label: {
                Label("Добавить друга", systemImage: "person.badge.plus")
            }
            .buttonStyle(GradientButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, Theme.s2)
        }
    }
}

struct FriendRowView: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: Theme.s3) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text("@" + friend.username)
                    .font(.bodyStrong)

                if friend.hasActiveStatus, let expiresAt = friend.expiresAt {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        let remaining = max(0, expiresAt.timeIntervalSince(ctx.date))
                        let h = Int(remaining) / 3600
                        let m = (Int(remaining) % 3600) / 60
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(h > 0 ? "\(h)ч \(m)м" : "\(m)м")
                                .monospacedDigit()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.mint)
                    }
                } else {
                    Text("офлайн")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if friend.hasActiveStatus,
                   let activities = friend.activities, !activities.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(activities.prefix(3), id: \.self) { act in
                            Text(act)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.coral.opacity(0.12))
                                .foregroundStyle(Theme.coral)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            if let district = friend.district {
                Label(district, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }
        }
        .glassCard(padding: Theme.s3)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(friend.hasActiveStatus
                      ? AnyShapeStyle(Theme.auroraGradient)
                      : AnyShapeStyle(Color.secondary.opacity(0.2)))
                .frame(width: 48, height: 48)

            Text(String(friend.username.prefix(1)).uppercased())
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if friend.hasActiveStatus {
                Circle()
                    .fill(Theme.mint)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
                    .offset(x: 18, y: 18)
            }
        }
    }
}

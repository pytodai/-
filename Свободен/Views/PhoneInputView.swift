import SwiftUI

struct PhoneInputView: View {
    @Bindable var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Свободен")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("Введите номер телефона")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("+7 (999) 000-00-00", text: $authVM.phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await authVM.requestCode() }
            } label: {
                Group {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Продолжить").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(authVM.phone.isEmpty || authVM.isLoading)
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

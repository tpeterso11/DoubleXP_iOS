//
//  LoginView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    /// Parent (RootView) passes this; on success you can route to `.main`.
    let onLoginSuccess: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Sign In")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    TextField("email", text: Binding(
                        get: { viewModel.email },
                        set: { viewModel.updateEmail($0) }
                    ))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                    SecureField("password", text: Binding(
                        get: { viewModel.password },
                        set: { viewModel.updatePassword($0) }
                    ))
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                }

                Button(action: {
                    viewModel.loginWithEmail(onSuccess: onLoginSuccess)
                }) {
                    Text("log in")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isLoginButtonEnabled ? Color.white : Color.white.opacity(0.3))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isLoginButtonEnabled)

                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.loginWithGoogle(onSuccess: onLoginSuccess)
                    }) {
                        Text("continue with google")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        viewModel.loginWithApple(onSuccess: onLoginSuccess)
                    }) {
                        Text("continue with apple")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                Spacer()

                Button(action: {
                    // TODO: hook up registration flow when you move RegisterActivity to SwiftUI.
                }) {
                    Text("create an account")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .underline()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 80)

            if viewModel.isWorking {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("login error"),
                message: Text(viewModel.errorMessage ?? "there was an error logging you in. please try again."),
                dismissButton: .default(Text("OK")) {
                    // no-op; spinner is already stopped in view model
                }
            )
        }
    }
}
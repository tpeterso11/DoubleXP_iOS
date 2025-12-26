//
//  LoginViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import FirebaseAuth
import FirebaseDatabase

@MainActor
final class LoginViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    // MARK: - Published UI State

    @Published var email: String = "" {
        didSet { reevaluateLoginButton() }
    }

    @Published var password: String = "" {
        didSet { reevaluateLoginButton() }
    }

    @Published var isWorking: Bool = false
    @Published var isLoginButtonEnabled: Bool = false

    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false

    // MARK: - Internal State

    private var pendingCompletion: (() -> Void)?
    private var currentNonce: String?

    // MARK: - Public API

    func updateEmail(_ newValue: String) {
        email = newValue
    }

    func updatePassword(_ newValue: String) {
        password = newValue
    }

    func loginWithEmail(onSuccess: @escaping () -> Void) {
        guard !email.isEmpty, password.count > 4 else { return }
        isWorking = true
        errorMessage = nil
        showError = false

        let manager = FirebaseAuthManager()
        manager.signIn(email: email, pass: password) { [weak self] errorCode, success in
            guard let self = self else { return }

            if success {
                guard let userID = Auth.auth().currentUser?.uid else {
                    self.isWorking = false
                    self.errorMessage = "there was an error logging you in. please try again."
                    self.showError = true
                    return
                }

                UserDefaults.standard.set(userID, forKey: "userId")

                // This replaces your old `downloadDBRef` path.
                // Move your existing user bootstrap logic into this helper.
                self.handlePostAuth(uid: userID,
                                    registrationType: "email",
                                    accessToken: nil,
                                    socialUserId: nil,
                                    onSuccess: onSuccess)
            } else {
                self.isWorking = false
                let friendly = self.mapFirebaseError(code: errorCode)
                self.errorMessage = friendly
                self.showError = true
            }
        }
    }

    func loginWithGoogle(onSuccess: @escaping () -> Void) {
        guard let rootVC = Self.currentRootViewController else {
            errorMessage = "unable to start google login. please try again."
            showError = true
            return
        }

        isWorking = true
        errorMessage = nil
        showError = false
        pendingCompletion = onSuccess

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC,
            hint: nil,
            additionalScopes: ["email", "https://www.googleapis.com/auth/youtube.readonly"]
        ) { [weak self] result, error in
            guard let self = self else { return }

            if let signInError = error as? GIDSignInError {
                self.isWorking = false
                self.errorMessage = "there was an error getting you logged into google. try again, or try registering using your email."
                self.showError = true
                print("❌ Google sign-in error: \(signInError)")
                return
            }

            guard let user = result?.user else {
                self.isWorking = false
                self.errorMessage = "there was an error getting you logged into google. please try again."
                self.showError = true
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: user.idToken?.tokenString ?? "",
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let err = error {
                    self.isWorking = false
                    self.errorMessage = "there was an error logging you in with google. please try again."
                    self.showError = true
                    print("❌ Firebase Google Auth error: \(err)")
                    return
                }

                guard let authResult = authResult else {
                    self.isWorking = false
                    self.errorMessage = "unable to complete google login. please try again."
                    self.showError = true
                    return
                }

                let uid = authResult.user.uid
                UserDefaults.standard.set(uid, forKey: "userId")

                var socialUserId: String? = nil
                if let googleId = user.userID, !googleId.isEmpty {
                    socialUserId = googleId
                }

                let accessToken = user.accessToken.tokenString

                self.handlePostAuth(
                    uid: uid,
                    registrationType: "google",
                    accessToken: accessToken,
                    socialUserId: socialUserId,
                    onSuccess: onSuccess
                )
            }
        }
    }

    func loginWithApple(onSuccess: @escaping () -> Void) {
        guard #available(iOS 13, *) else {
            errorMessage = "apple sign-in is only available on ios 13 and later."
            showError = true
            return
        }

        isWorking = true
        errorMessage = nil
        showError = false
        pendingCompletion = onSuccess

        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Registration / Post-Auth Hook

    private func handlePostAuth(
        uid: String,
        registrationType: String,
        accessToken: String?,
        socialUserId: String?,
        onSuccess: @escaping () -> Void
    ) {
        // This is where your old `downloadDBRef` logic lived.
        // For now, we keep it very simple: mark working as done and call onSuccess.
        // If you have more complex logic (new vs existing user, registration flow),
        // move it here and drive navigation from the result.

        isWorking = false

        // Example: you might call into a shared bootstrap service:
        // LoginBootstrapService.shared.bootstrapUser(
        //    uid: uid,
        //    registrationType: registrationType,
        //    accessToken: accessToken,
        //    socialUserId: socialUserId
        // ) { isNewUser in ... }

        onSuccess()
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        Self.currentWindow ?? ASPresentationAnchor()
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            isWorking = false
            return
        }

        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            print("❌ Unable to fetch Apple identity token")
            isWorking = false
            return
        }

        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("❌ Unable to serialize Apple token string from data: \(appleIDToken.debugDescription)")
            isWorking = false
            return
        }

        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }

            if let err = error {
                print("❌ Firebase Apple Auth error: \(err)")
                self.isWorking = false
                self.errorMessage = "there was an error logging you in with apple. please try again."
                self.showError = true
                return
            }

            guard let authResult = authResult else {
                self.isWorking = false
                self.errorMessage = "unable to complete apple login. please try again."
                self.showError = true
                return
            }

            let uid = authResult.user.uid
            UserDefaults.standard.set(uid, forKey: "userId")

            self.handlePostAuth(
                uid: uid,
                registrationType: "apple",
                accessToken: nil,
                socialUserId: nil,
                onSuccess: self.pendingCompletion ?? {}
            )
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple sign-in error: \(error)")
        isWorking = false
        errorMessage = "there was an error logging you in with apple. please try again."
        showError = true
    }

    // MARK: - Helpers

    private func reevaluateLoginButton() {
        if !email.isEmpty && !password.isEmpty && password.count > 4 {
            isLoginButtonEnabled = true
        } else {
            isLoginButtonEnabled = false
        }
    }

    private func mapFirebaseError(code: String) -> String {
        switch code {
        case "17007":
            return "sorry, that email is already in use."
        case "17008":
            return "sorry, please enter a valid email to continue."
        case "17009":
            return "sorry, that password is incorrect. please try again."
        case "17011":
            return "sorry, we do not have that user in our database."
        default:
            return "there was an error logging you in. please try again."
        }
    }

    private static var currentWindow: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return scene.windows.first { $0.isKeyWindow }
    }

    private static var currentRootViewController: UIViewController? {
        currentWindow?.rootViewController
    }

    // MARK: - Nonce / Hash Helpers (from your original controller)

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.map { String(format: "%02x", $0) }.joined()
        return hashString
    }
}
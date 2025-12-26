//
//  EditProfileView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/27/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import UIKit

enum EditProfileColors {
    static let background        = Color(red: 0.039, green: 0.039, blue: 0.039)   // #0A0A0A
    static let cardBackground    = Color(red: 0.078, green: 0.078, blue: 0.078)   // #141414
    static let cardGradientStart = Color(red: 0.102, green: 0.102, blue: 0.180)   // #1A1A2E
    static let cardGradientEnd   = Color(red: 0.086, green: 0.129, blue: 0.243)   // #16213E

    static let coralStart = Color(red: 1.000, green: 0.420, blue: 0.420)          // #FF6B6B
    static let coralEnd   = Color(red: 1.000, green: 0.557, blue: 0.325)          // #FF8E53
    static let greenStart = Color(red: 0.298, green: 0.851, blue: 0.392)          // #4CD964
    static let greenEnd   = Color(red: 0.180, green: 0.800, blue: 0.443)          // #2ECC71

    static let systemBlue   = Color(red: 0.000, green: 0.478, blue: 1.000)        // #007AFF
    static let systemOrange = Color(red: 1.000, green: 0.584, blue: 0.000)        // #FF9500
    static let systemGreen  = Color(red: 0.298, green: 0.851, blue: 0.392)        // #4CD964

    static let googleBlue  = Color(red: 0.259, green: 0.522, blue: 0.957)        // #4285F4
    static let googleRed   = Color(red: 0.918, green: 0.263, blue: 0.208)        // #EA4335
    static let youtubeRed  = Color(red: 1.000, green: 0.000, blue: 0.000)        // #FF0000

    // Socials
    static let discord   = Color(red: 0.345, green: 0.396, blue: 0.949)          // #5865F2
    static let twitter   = Color(red: 0.114, green: 0.631, blue: 0.949)          // #1DA1F2
    static let instagram = Color(red: 0.882, green: 0.188, blue: 0.424)          // #E1306C
    static let tiktok    = Color(red: 0.000, green: 0.000, blue: 0.000)          // #000000
    static let twitch    = Color(red: 0.569, green: 0.275, blue: 1.000)          // #9146FF
}

@MainActor
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditProfileViewModel

    @FocusState private var focusedField: Field?
    @State private var showUnsavedChangesAlert = false
    @State private var showSaveConfirmation = false
    @State private var isPerformingSave = false
    @State private var isShowingAboutMeTags = false
    @State private var isShowingLookingForTags = false
    @State private var isShowingGameSelection = false
    @State private var isShowingPokoSelection = false
    @State private var isShowingVideoManager = false
    @State private var isShowingQuizList = false
    
    // Poko animation states
    @State private var pokoImageOpacity: Double = 1.0
    @State private var pokoImageScale: CGFloat = 1.0
    @State private var previousPokoId: String?

    enum Field: Hashable {
        case displayName
        case tagline
        case bio
        case discord
        case twitter
        case instagram
        case tiktok
        case twitch
    }

    // Default initializer
    init() {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel())
    }

    // Injectable initializer if you want to pass a pre-configured VM
    init(viewModel: EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var isKeyboardVisible: Bool {
        focusedField != nil
    }

    private var isEditingMultiline: Bool {
        focusedField == .bio
    }

    var body: some View {
        ZStack {
            EditProfileColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    profileCard
                    basicInfoSection
                    socialsSection
                    quizSection
                    googleAccountSection
                    customizeSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            // Work overlay while saving
            if isPerformingSave {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.2)

                    Text("Saving your profile…")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Hang tight for a sec.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 16)
            }

            // Light confirmation toast
            if showSaveConfirmation {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("Profile updated")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                        Spacer()
                    }
                    .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .onAppear {
            viewModel.load()
            // Store initial poko ID for change detection
            previousPokoId = PokoProvider.shared.userSelectedPoko?.id
        }
        .onReceive(NotificationCenter.default.publisher(for: .userPokoDidChange)) { notification in
            // Animate poko change when we receive the notification
            if let newPoko = notification.userInfo?["poko"] as? Poko,
               newPoko.id != previousPokoId {
                animatePokoChange(to: newPoko)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // BACK
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if viewModel.hasChanges {
                        PopupManager.showUnsavedProfileChangesPopup(
                            onSaveAndExit: {
                                viewModel.saveProfile { success in
                                    if success {
                                        // Make sure we dismiss on the main thread
                                        DispatchQueue.main.async {
                                            dismiss()
                                        }
                                    }
                                }
                            },
                            onDiscard: {
                                // Just bail out, forget changes
                                dismiss()
                            },
                            onCancel: {
                                // Do nothing – user stays on the page
                            }
                        )
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // TITLE
            ToolbarItem(placement: .principal) {
                Text("Edit Profile")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // SAVE – hidden while keyboard is visible or we're in the work phase
            if !isKeyboardVisible && !isPerformingSave {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        performSaveAndDismiss()
                    }) {
                        HStack(spacing: 6) {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                            Text("Save")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [EditProfileColors.greenStart, EditProfileColors.greenEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .opacity(viewModel.hasChanges && !viewModel.isSaving ? 1.0 : 0.35)
                    }
                    .disabled(!viewModel.hasChanges || viewModel.isSaving)
                }
            }

            // KEYBOARD TOOLBAR – "Update" only for Bio
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                if isEditingMultiline && !isPerformingSave {
                    Button(action: {
                        dismissKeyboard()
                    }) {
                        Text("Update")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [EditProfileColors.greenStart, EditProfileColors.greenEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .toolbarBackground(EditProfileColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }

            Button("Save & Exit") {
                performSaveAndDismiss()
            }
        } message: {
            Text("You have unsaved changes. Do you want to discard them?")
        }
        .disabled(isPerformingSave) // prevent interaction during work view
        .fullScreenCover(isPresented: $isShowingAboutMeTags) {
            NavigationStack {
                TagSelectionView(
                    mode: .aboutMe,
                    initialSelection: Set(UserProvider.shared.getUser()?.userAbout ?? [])
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingLookingForTags) {
            NavigationStack {
                TagSelectionView(
                    mode: .lookingFor,
                    initialSelection: Set(UserProvider.shared.getUser()?.userLookingFor ?? [])
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingGameSelection) {
            NavigationStack {
                GameSelectionView(
                    isOnboarding: false,  // No skip/progress dots
                    onComplete: { selectedGames in
                        handleGameSelectionComplete(selectedGames)
                        isShowingGameSelection = false
                    },
                    onSkip: nil,
                    onSeeMore: { }
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingPokoSelection) {
            NavigationStack {
                PokoSelectionView(
                    isOnboarding: false,
                    onSelectionConfirmed: { selectedPoko in
                        // Selection is saved to Firebase automatically by the ViewModel
                        // Animation will be triggered by the notification
                        isShowingPokoSelection = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingVideoManager) {
            NavigationStack {
                GoogleVideoManagerView(userId: UserProvider.shared.getUser()?.uId)
            }
        }
        .fullScreenCover(isPresented: $isShowingQuizList) {
            NavigationStack {
                GameQuizListView(userId: UserProvider.shared.getUser()?.uId ?? "")
            }
        }
        .onChange(of: isShowingVideoManager) { _, isShowing in
            // When video manager is dismissed, refresh video data
            if !isShowing {
                Task {
                    await viewModel.refreshGoogleData()
                }
            }
        }
    }
    
    // MARK: - Poko Animation
    
    private func animatePokoChange(to newPoko: Poko) {
        // Phase 1: Fade out and shrink current image
        withAnimation(.easeIn(duration: 0.2)) {
            pokoImageOpacity = 0
            pokoImageScale = 0.8
        }
        
        // Phase 2: Update the image (via viewModel notification) then pop in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // Update tracked ID
            previousPokoId = newPoko.id
            
            // Reset scale for pop effect
            pokoImageScale = 0.5
            
            // Phase 3: Pop in with spring animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                pokoImageOpacity = 1
                pokoImageScale = 1.0
            }
        }
    }
    
    private func handleGameSelectionComplete(_ games: [GamerConnectGame]) {
        viewModel.updateSelectedGames(games)
    }
    
    // MARK: - Save flow

    private func performSaveAndDismiss() {
        guard !isPerformingSave else { return }

        // Start work overlay
        isPerformingSave = true
        let start = Date()

        viewModel.saveProfile { success in
            let elapsed = Date().timeIntervalSince(start)
            let minDelay: TimeInterval = 3.0
            let remaining = max(minDelay - elapsed, 0)

            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                isPerformingSave = false

                guard success else {
                    // If we failed, we just stay on screen; error is in viewModel.error
                    return
                }

                withAnimation(.easeOut(duration: 0.25)) {
                    showSaveConfirmation = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showSaveConfirmation = false
                    }
                    dismiss()
                }
            }
        }
    }

    // MARK: - Profile Card
    
    private var profileCard: some View {
        VStack(spacing: 16) {
            // Avatar with gradient ring - NOW WITH ANIMATION
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [EditProfileColors.coralStart, EditProfileColors.coralEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(Color.black)
                            .frame(width: 94, height: 94)
                    )
                    .overlay(
                        Group {
                            if let image = viewModel.pokoImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(Circle())
                                    .padding(8)
                                    .opacity(pokoImageOpacity)
                                    .scaleEffect(pokoImageScale)
                            } else if viewModel.isLoadingPokoImage {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    )
            }
            
            // Username display
            Text(viewModel.displayName.isEmpty ? "Username" : viewModel.displayName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(
                viewModel.tagline
            )
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.5))
            
            // Poko button - NOW WIRED UP
            Button(action: { isShowingPokoSelection = true }) {
                HStack(spacing: 8) {
                    Text("🎭")
                    Text("My Pokos")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(EditProfileColors.coralStart)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(EditProfileColors.coralStart.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(EditProfileColors.coralStart.opacity(0.4), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [EditProfileColors.cardGradientStart, EditProfileColors.cardGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "BASIC INFO")
            
            VStack(spacing: 0) {
                EditableRow(
                    label: "Display Name",
                    value: $viewModel.displayName,
                    placeholder: "Enter your name",
                    isMultiline: false,
                    onDone: {
                        dismissKeyboard()
                    },
                    maxLength: nil,
                    showCounter: false,
                    field: EditProfileView.Field.displayName,
                    focus: $focusedField
                )
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                EditableRow(
                    label: "Tagline",
                    value: $viewModel.tagline,
                    placeholder: "Add a tagline...",
                    isMultiline: false,
                    onDone: {
                        dismissKeyboard()
                    },
                    maxLength: 500,
                    showCounter: true,
                    field: EditProfileView.Field.tagline,
                    focus: $focusedField
                )
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                EditableRow(
                    label: "Bio",
                    value: $viewModel.bio,
                    placeholder: "Tell others about yourself...",
                    isMultiline: true,
                    onDone: nil,
                    maxLength: 280,
                    showCounter: true,
                    field: EditProfileView.Field.bio,
                    focus: $focusedField
                )
            }
            .background(EditProfileColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "PLAYSTYLE PROFILE")
            
            Button(action: { isShowingQuizList = true }) {
                HStack(spacing: 16) {
                    // Quiz icon with gradient
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.2),
                                        Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Gaming Quizzes")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            
                            // NEW badge for first-time users
                            if !UserDefaults.standard.bool(forKey: "hasSeenGameQuizIntro") {
                                Text("NEW")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text("Share your playstyle • Get better matches")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Right side indicator
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                        Text("Start")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15))
                    .clipShape(Capsule())
                }
                .padding(16)
                .background(EditProfileColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.2),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(EditProfileScaleButtonStyle())
        }
    }
    
    // MARK: - Socials Section
    
    private var socialsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(title: "SOCIALS")
                Spacer()
                Button(action: {}) {
                    Text("Edit All")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(EditProfileColors.systemBlue)
                }
            }
            
            VStack(spacing: 0) {
                SocialRow(
                    icon: "bubble.left.fill",
                    iconColor: EditProfileColors.discord,
                    platform: "Discord",
                    value: $viewModel.discord,
                    placeholder: "username#0000",
                    field: .discord,
                    focus: $focusedField
                )
                
                Divider().background(Color.white.opacity(0.06))
                
                SocialRow(
                    icon: "bird.fill",
                    iconColor: EditProfileColors.twitter,
                    platform: "Twitter",
                    value: $viewModel.twitter,
                    placeholder: "@username",
                    field: .twitter,
                    focus: $focusedField
                )
                
                Divider().background(Color.white.opacity(0.06))
                
                SocialRow(
                    icon: "camera.fill",
                    iconColor: EditProfileColors.instagram,
                    platform: "Instagram",
                    value: $viewModel.instagram,
                    placeholder: "@username",
                    field: .instagram,
                    focus: $focusedField
                )
                
                Divider().background(Color.white.opacity(0.06))
                
                SocialRow(
                    icon: "music.note",
                    iconColor: .white,
                    platform: "TikTok",
                    value: $viewModel.tiktok,
                    placeholder: "@username",
                    field: .tiktok,
                    focus: $focusedField
                )
                
                Divider().background(Color.white.opacity(0.06))
                
                SocialRow(
                    icon: "tv.fill",
                    iconColor: EditProfileColors.twitch,
                    platform: "Twitch",
                    value: $viewModel.twitch,
                    placeholder: "username",
                    field: .twitch,
                    focus: $focusedField
                )
            }
            .background(EditProfileColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Google Account Section
    
    private var googleAccountSection: some View {
         VStack(alignment: .leading, spacing: 14) {
             sectionHeader(title: "YOUTUBE VIDEOS")
             
             Button(action: { isShowingVideoManager = true }) {
                 HStack(spacing: 16) {
                     // YouTube icon
                     ZStack {
                         RoundedRectangle(cornerRadius: 12)
                             .fill(
                                 viewModel.isGoogleConnected
                                     ? EditProfileColors.youtubeRed.opacity(0.15)
                                     : Color.white.opacity(0.08)
                             )
                             .frame(width: 44, height: 44)
                         
                         Image(systemName: "play.rectangle.fill")
                             .font(.system(size: 20))
                             .foregroundColor(
                                 viewModel.isGoogleConnected
                                     ? EditProfileColors.youtubeRed
                                     : .white.opacity(0.5)
                             )
                     }
                     
                     VStack(alignment: .leading, spacing: 2) {
                         if viewModel.isGoogleConnected {
                             Text("Manage Videos")
                                 .font(.system(size: 15, weight: .semibold))
                                 .foregroundColor(.white)
                             
                             if viewModel.videoCount > 0 {
                                 Text("\(viewModel.videoCount) video\(viewModel.videoCount == 1 ? "" : "s") on profile")
                                     .font(.system(size: 12))
                                     .foregroundColor(.white.opacity(0.5))
                             } else {
                                 Text("Add videos to your profile")
                                     .font(.system(size: 12))
                                     .foregroundColor(.white.opacity(0.5))
                             }
                         } else {
                             Text("Add YouTube Videos")
                                 .font(.system(size: 15, weight: .semibold))
                                 .foregroundColor(.white)
                             
                             Text("Showcase your best gaming moments")
                                 .font(.system(size: 12))
                                 .foregroundColor(.white.opacity(0.5))
                         }
                     }
                     
                     Spacer()
                     
                     // Right side indicator
                     if viewModel.isGoogleConnected {
                         Image(systemName: "chevron.right")
                             .font(.system(size: 14, weight: .medium))
                             .foregroundColor(.white.opacity(0.3))
                     } else {
                         HStack(spacing: 4) {
                             Image(systemName: "plus.circle.fill")
                                 .font(.system(size: 14))
                             Text("Connect")
                                 .font(.system(size: 12, weight: .semibold))
                         }
                         .foregroundColor(EditProfileColors.youtubeRed)
                         .padding(.horizontal, 12)
                         .padding(.vertical, 6)
                         .background(EditProfileColors.youtubeRed.opacity(0.15))
                         .clipShape(Capsule())
                     }
                 }
                 .padding(16)
                 .background(EditProfileColors.cardBackground)
                 .clipShape(RoundedRectangle(cornerRadius: 16))
                 .overlay(
                     RoundedRectangle(cornerRadius: 16)
                         .stroke(
                             viewModel.isGoogleConnected
                                 ? EditProfileColors.youtubeRed.opacity(0.2)
                                 : Color.white.opacity(0.08),
                             lineWidth: 1
                         )
                 )
             }
             .buttonStyle(EditProfileScaleButtonStyle())
         }
     }
    
    // MARK: - Customize Section
    
    private var customizeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "CUSTOMIZE")
            
            VStack(spacing: 10) {
                LinkCard(
                    icon: "gamecontroller.fill",
                    iconBackground: LinearGradient(
                        colors: [EditProfileColors.systemBlue.opacity(0.2), EditProfileColors.systemBlue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    title: "My Games",
                    subtitle: "\(viewModel.gamesCount) games • Tap to edit",
                    action: {
                        isShowingGameSelection = true  // Opens GameSelectionView
                    }
                )
                
                LinkCard(
                    icon: "sparkles",
                    iconBackground: LinearGradient(
                        colors: [EditProfileColors.systemOrange.opacity(0.2), EditProfileColors.systemOrange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    title: "About Me",
                    subtitle: "\(viewModel.aboutMeCount) tags • Tap to edit",
                    action: {
                        isShowingAboutMeTags = true
                    }
                )
                
                LinkCard(
                    icon: "magnifyingglass",
                    iconBackground: LinearGradient(
                        colors: [EditProfileColors.systemGreen.opacity(0.2), EditProfileColors.systemGreen.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    title: "Looking For",
                    subtitle: "\(viewModel.lookingForCount) preferences • Tap to edit",
                    action: {
                        isShowingLookingForTags = true
                    }
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.5)
            .foregroundColor(.white.opacity(0.5))
    }
}

// MARK: - Supporting Views

struct EditableRow: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    var isMultiline: Bool
    var onDone: (() -> Void)?
    var maxLength: Int?
    var showCounter: Bool

    // Focus wiring so parent can track keyboard state
    let field: EditProfileView.Field?
    var focus: FocusState<EditProfileView.Field?>.Binding?

    init(
        label: String,
        value: Binding<String>,
        placeholder: String,
        isMultiline: Bool = false,
        onDone: (() -> Void)? = nil,
        maxLength: Int? = nil,
        showCounter: Bool = false,
        field: EditProfileView.Field? = nil,
        focus: FocusState<EditProfileView.Field?>.Binding? = nil
    ) {
        self.label = label
        self._value = value
        self.placeholder = placeholder
        self.isMultiline = isMultiline
        self.onDone = onDone
        self.maxLength = maxLength
        self.showCounter = showCounter
        self.field = field
        self.focus = focus
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                if showCounter, let maxLength {
                    Text("\(min(value.count, maxLength))/\(maxLength)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            if isMultiline {
                // Multi-line: allow returns, standard behavior
                if let focus = focus, let field = field {
                    TextField(placeholder, text: $value, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .lineLimit(3...6)
                        .focused(focus, equals: field)
                } else {
                    TextField(placeholder, text: $value, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .lineLimit(3...6)
                }
            } else {
                // Single-line: use Done key + fire onDone
                if let focus = focus, let field = field {
                    TextField(placeholder, text: $value)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .submitLabel(.done)
                        .focused(focus, equals: field)
                        .onSubmit {
                            onDone?()
                        }
                } else {
                    TextField(placeholder, text: $value)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .submitLabel(.done)
                        .onSubmit {
                            onDone?()
                        }
                }
            }
        }
        .padding(16)
    }
}

struct SocialRow: View {
    let icon: String
    let iconColor: Color
    let platform: String
    @Binding var value: String
    let placeholder: String
    let field: EditProfileView.Field
    var focus: FocusState<EditProfileView.Field?>.Binding
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                TextField(placeholder, text: $value)
                    .font(.system(size: 15))
                    .foregroundColor(value.isEmpty ? .white.opacity(0.3) : .white)
                    .submitLabel(.done)
                    .focused(focus, equals: field)
                    .onSubmit {
                        dismissKeyboard()
                    }
            }
            
            Spacer()
        }
        .padding(16)
    }
}

struct LinkCard: View {
    let icon: String
    let iconBackground: LinearGradient
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(iconBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(18)
            .background(EditProfileColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(EditProfileScaleButtonStyle())
    }
}

/*struct VideoThumbnailCard: View {
    let video: ProfileVideo
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                        .aspectRatio(16/9, contentMode: .fit)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(video.duration)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(6)
                        }
                    }
                }
                
                Text(video.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white, Color.black.opacity(0.6))
            }
            .offset(x: 6, y: -6)
        }
    }
}*/

struct EditProfileScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

//
//  TagSelectionView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/28/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

@MainActor
struct TagSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: TagSelectionViewModel

    @State private var isPerformingSave: Bool = false
    @State private var showSaveConfirmation: Bool = false

    // MARK: - Init

    init(mode: TagSelectionMode, initialSelection: Set<String>) {
        _viewModel = StateObject(wrappedValue: TagSelectionViewModel(mode: mode, initialSelection: initialSelection))
    }

    // MARK: - Computed

    private var selectedCount: Int {
        viewModel.selectedTags.count
    }

    private var suggestedCount: Int {
        viewModel.sections.reduce(0) { $0 + $1.tags.count }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            EditProfileColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
                footer
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

                    Text("Saving your \(viewModel.mode == .aboutMe ? "About Me" : "Looking For") tags…")
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
                            Text("Tags updated")
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
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden, for: .navigationBar)
        .disabled(isPerformingSave)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Back button
            Button(action: handleBackTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 999)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.08),
                                            Color.black.opacity(0.9)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .frame(width: 30, height: 30)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.mode.title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundColor(.white.opacity(0.8))

                Text(viewModel.mode.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            Spacer()

            Text(viewModel.mode.stepLabel)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                )
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.96),
                    Color.black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(viewModel.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.0)
                            .textCase(.uppercase)
                            .foregroundColor(Color.white.opacity(0.65))

                        if let caption = section.caption {
                            Text(caption)
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.6))
                        }

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ],
                            alignment: .leading,
                            spacing: 8
                        ) {
                            ForEach(section.tags, id: \.self) { tag in
                                let isSelected = viewModel.selectedTags.contains(tag)
                                Button(action: {
                                    viewModel.toggleTag(tag)
                                }) {
                                    HStack(spacing: 6) {
                                        Text(isSelected ? "✓" : "●")
                                            .font(.system(size: 11, weight: .medium))
                                            .opacity(isSelected ? 1.0 : 0.9)

                                        Text(tag)
                                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        ZStack {
                                            if isSelected {
                                                LinearGradient(
                                                    colors: [EditProfileColors.greenStart, EditProfileColors.greenEnd],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            } else {
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.08),
                                                        Color.black.opacity(0.9)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            }
                                        }
                                    )
                                    .foregroundColor(isSelected ? Color.black.opacity(0.9) : Color.white.opacity(0.9))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                isSelected
                                                ? Color.clear
                                                : Color.white.opacity(0.25),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(
                                        color: isSelected
                                        ? Color.green.opacity(0.35)
                                        : Color.clear,
                                        radius: isSelected ? 10 : 0,
                                        x: 0,
                                        y: 10
                                    )
                                }
                                .buttonStyle(EditProfileScaleButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Selected Tags")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.9)
                    .textCase(.uppercase)
                    .foregroundColor(Color.white.opacity(0.7))

                Text("\(selectedCount) of \(suggestedCount) suggested")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.85))
            }

            Spacer()

            Button(action: {
                performSaveAndDismiss()
            }) {
                HStack(spacing: 8) {
                    if viewModel.isSaving || isPerformingSave {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.black)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }

                    Text(viewModel.mode.saveButtonTitle)
                        .font(.system(size: 13, weight: .bold))
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [EditProfileColors.greenStart, EditProfileColors.greenEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(Color.black.opacity(0.95))
                .clipShape(Capsule())
                .shadow(color: Color.green.opacity(0.6), radius: 18, x: 0, y: 12)
                .opacity(viewModel.hasChanges ? 1.0 : 0.35)
            }
            .disabled(!viewModel.hasChanges || isPerformingSave)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.96),
                    Color.black.opacity(0.9)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Actions

    private func handleBackTap() {
        // Same treatment as EditProfileView:
        // If there are unsaved changes, show popup; otherwise just dismiss.
        if viewModel.hasChanges {
            PopupManager.showUnsavedProfileChangesPopup(
                onSaveAndExit: {
                    performSaveAndDismiss()
                },
                onDiscard: {
                    dismiss()
                },
                onCancel: {
                    // Do nothing, stay on the page
                }
            )
        } else {
            dismiss()
        }
    }

    private func performSaveAndDismiss() {
        guard !isPerformingSave else { return }

        isPerformingSave = true
        let start = Date()

        viewModel.saveSelections { success in
            let elapsed = Date().timeIntervalSince(start)
            let minDelay: TimeInterval = 3.0
            let remaining = max(minDelay - elapsed, 0)

            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                isPerformingSave = false

                guard success else {
                    // If we failed, just stay on the screen (error handling could be added later)
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
}

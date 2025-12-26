//
//  GameInviteCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct GameInviteCell: View {
    
    // --- THIS IS THE CHANGE ---
    // We now accept the RivalObj directly
    let rival: RivalObj
    
    // We can add a simple action handler for the buttons
    var onRespond: (String) -> Void = { _ in }
    
    var body: some View {
        // Main card container
        VStack(spacing: 0) {
            // Header: Game Art + Floating Friend
            ZStack(alignment: .bottomLeading) {
                // Game Art
                AsyncImage(url: URL(string: rival.gameImageUrl)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                } placeholder: {
                    Color.white.opacity(0.1)
                        .frame(height: 200)
                }
                .clipped()

                // Floating Friend Info
                HStack(spacing: 8) {
                    // RivalObj has no friend pic, so we use the placeholder
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.gray)
                    
                    Text(rival.gamerTag) // <-- Wired to rival.gamerTag
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .padding(12)
            }

            // Body: Title + Buttons
            VStack(alignment: .leading, spacing: 0) {
                // Top-left text content
                VStack(alignment: .leading) {
                    Text(rival.game) // <-- Wired to rival.game
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2) // Handles long titles
                    
                    Text(rival.type) // <-- Wired to rival.type
                        .font(.system(size: 14))
                        .foregroundColor(.blue.opacity(0.6))
                }
                
                Spacer() // Pushes buttons to the bottom

                // Bottom-right button group
                HStack(spacing: 16) {
                    Spacer() // Pushes group to the right
                    
                    // "Yes" Button
                    Button(action: { onRespond("accepted") }) {
                        VStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 20))
                                .frame(width: 48, height: 48)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                            
                            Text("yes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))
                                //.uppercased()
                        }
                    }
                    
                    // "No" Button
                    Button(action: { onRespond("rejected") }) {
                        VStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(.system(size: 20))
                                .frame(width: 48, height: 48)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                            
                            Text("no")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))
                                //.uppercased()
                        }
                    }
                    
                    // "Later" Button
                    Button(action: { onRespond("later") }) {
                        VStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .frame(width: 48, height: 48)
                                .background(Color.red.opacity(0.5))
                                .clipShape(Circle())
                            
                            Text("later")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))
                                //.uppercased()
                        }
                    }
                }
            }
            .padding(16)
            .frame(height: 144) // Gives a fixed height to the body
        }
        .background(Color.blue.opacity(0.2))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal) // Add padding to the whole cell
    }
}

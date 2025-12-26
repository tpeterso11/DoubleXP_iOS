//
//  CommunityToggleCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit

protocol CommunityToggleCellDelegate: AnyObject {
    //func didChangeMode(to mode: CommunityMode)
    func didTapInfoButton()
}

class ThreeStateToggleControl: UIControl {

    // MARK: - Properties
    
    public var selectedIndex: Int = 1 {
        didSet {
            if selectedIndex < 0 { selectedIndex = 0 }
            if selectedIndex > 2 { selectedIndex = 2 }
            updateThumbPosition(animated: true)
            sendActions(for: .valueChanged)
        }
    }
    
    private let thumbView = UIView()
    private let trackBackgroundView = UIView() // This will be the outer white rounded rectangle
    private let coloredTrackView = UIView() // This will hold the green, yellow, red segments

    private let greenView = UIView()
    private let yellowView = UIView()
    private let redView = UIView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    private func setupViews() {
        // Outer track background (white rounded rectangle)
        trackBackgroundView.backgroundColor = .white
        trackBackgroundView.layer.shadowColor = UIColor.black.cgColor
        trackBackgroundView.layer.shadowRadius = 3
        trackBackgroundView.layer.shadowOpacity = 0.1
        trackBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        addSubview(trackBackgroundView)
        
        // Inner colored track
        coloredTrackView.backgroundColor = .clear // Will be filled by segments
        coloredTrackView.clipsToBounds = true // Crucial for rounding the inner colored segments
        trackBackgroundView.addSubview(coloredTrackView) // Add to the background view
        
        // Color segments setup
        greenView.backgroundColor = .systemGreen
        yellowView.backgroundColor = .systemYellow
        redView.backgroundColor = .systemRed
        
        [greenView, yellowView, redView].forEach {
            coloredTrackView.addSubview($0)
        }
        
        // Thumb setup (the sliding circle)
        thumbView.backgroundColor = .white
        thumbView.layer.shadowColor = UIColor.black.cgColor
        thumbView.layer.shadowRadius = 2
        thumbView.layer.shadowOpacity = 0.2
        thumbView.layer.shadowOffset = CGSize(width: 0, height: 1)
        addSubview(thumbView) // Add directly to self to be above trackBackgroundView
    }
    
    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // The outer track background should match the control's bounds and be rounded
        trackBackgroundView.frame = bounds
        trackBackgroundView.layer.cornerRadius = bounds.height / 2
        
        // The colored track should be slightly inset to create the white border effect
        let inset: CGFloat = 2 // Adjust this value for desired border thickness
        coloredTrackView.frame = bounds.insetBy(dx: inset, dy: inset)
        coloredTrackView.layer.cornerRadius = coloredTrackView.bounds.height / 2
        
        let segmentWidth = coloredTrackView.bounds.width / 3
        greenView.frame = CGRect(x: 0, y: 0, width: segmentWidth, height: coloredTrackView.bounds.height)
        yellowView.frame = CGRect(x: segmentWidth, y: 0, width: segmentWidth, height: coloredTrackView.bounds.height)
        redView.frame = CGRect(x: segmentWidth * 2, y: 0, width: segmentWidth, height: coloredTrackView.bounds.height)
        
        // Set thumb size and initial position
        let thumbSize = bounds.height - (inset * 2) // Thumb should fit within the inner colored track height
        thumbView.frame = CGRect(x: 0, y: 0, width: thumbSize, height: thumbSize)
        thumbView.layer.cornerRadius = thumbSize / 2
        updateThumbPosition(animated: false)
    }
    
    private func updateThumbPosition(animated: Bool) {
        let inset: CGFloat = 2 // Match the inset used in layoutSubviews
        let innerTrackWidth = bounds.width - (inset * 2)
        let segmentWidth = innerTrackWidth / 3
        let thumbWidth = thumbView.bounds.width
        
        // Calculate the target center X relative to the inner colored track
        let targetCenterXInColoredTrack = (CGFloat(selectedIndex) * segmentWidth) + (segmentWidth / 2)
        
        // Adjust for the inset to get the position relative to the whole control
        let newFrame = CGRect(
            x: targetCenterXInColoredTrack - (thumbWidth / 2) + inset, // Add inset for overall position
            y: (bounds.height - thumbWidth) / 2,
            width: thumbWidth,
            height: thumbWidth
        )
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
                self.thumbView.frame = newFrame
            }
        } else {
            thumbView.frame = newFrame
        }
    }

    // MARK: - Gesture Handling
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let segmentWidth = bounds.width / 3 // Use overall width for tap detection
        let index = Int(location.x / segmentWidth)
        selectedIndex = index
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let segmentWidth = bounds.width / 3 // Use overall width for pan detection
        
        switch gesture.state {
        case .ended, .cancelled:
            let index = Int(round(location.x / segmentWidth))
            selectedIndex = index
        default:
            // Optionally, you could make the thumb follow the finger during the pan,
            // but for a discrete 3-state toggle, snapping on end is cleaner.
            break
        }
    }
}


class CommunityToggleCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityToggleCell"
    weak var delegate: CommunityToggleCellDelegate?
    
    private let labels = ["Beginner", "Normal", "Hardcore"]
    private let colors: [UIColor] = [.systemGreen, .systemYellow, .systemRed]
    
    // MARK: - UI Components
    
    private lazy var toggleControl: ThreeStateToggleControl = {
        let control = ThreeStateToggleControl()
        control.selectedIndex = 1 // Default to NORMAL
        control.addTarget(self, action: #selector(toggleValueChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 2. Add the new infoButton property
    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        // Use a symbol configuration to size the icon appropriately
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        button.setImage(UIImage(systemName: "info.circle", withConfiguration: config), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        updateStatusLabel(for: toggleControl.selectedIndex) // now shows "Normal"
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    // MARK: - Layout Setup
    
    private func setupLayout() {
        // 3. Add all three components to the content view
        contentView.addSubview(toggleControl)
        contentView.addSubview(statusLabel)
        contentView.addSubview(infoButton)
        
        // 4. Update the layout constraints
        NSLayoutConstraint.activate([
            // Info Button is now pinned to the trailing edge.
            infoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            infoButton.centerYAnchor.constraint(equalTo: toggleControl.centerYAnchor),
            
            // Toggle control is positioned to the left of the info button.
            // The top anchor constant is removed to help reduce space.
            toggleControl.topAnchor.constraint(equalTo: contentView.topAnchor),
            toggleControl.trailingAnchor.constraint(equalTo: infoButton.leadingAnchor, constant: -8),
            toggleControl.widthAnchor.constraint(equalToConstant: 80),
            toggleControl.heightAnchor.constraint(equalToConstant: 25),
            
            // Status label remains centered under the toggle control.
            statusLabel.topAnchor.constraint(equalTo: toggleControl.bottomAnchor, constant: 4),
            statusLabel.centerXAnchor.constraint(equalTo: toggleControl.centerXAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func toggleValueChanged(_ sender: ThreeStateToggleControl) {
        let index = sender.selectedIndex
        updateStatusLabel(for: index)
        
        /*let mode: CommunityMode
        switch index {
        case 0: mode = .beginner
        case 1: mode = .normal
        case 2: mode = .hardcore
        default: mode = .beginner
        }
        
        delegate?.didChangeMode(to: mode)*/
    }
    
    // 5. Add the action method for the info button
    @objc private func infoButtonTapped() {
        delegate?.didTapInfoButton()
    }
    
    private func updateStatusLabel(for index: Int) {
        guard index >= 0 && index < labels.count else { return }
        statusLabel.text = labels[index]
        statusLabel.textColor = colors[index]
    }
}

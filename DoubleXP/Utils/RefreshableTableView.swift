//
//  RefreshableTableView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/6/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit

class RefreshableTableView: UITableView {

    private var isRefreshing = false
    private let refreshThreshold: CGFloat = 80
    private let spinner = UIActivityIndicatorView(style: .medium)

    var onRefresh: (() -> Void)?

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.topAnchor.constraint(equalTo: topAnchor, constant: -40)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !isRefreshing, contentOffset.y < -refreshThreshold {
            beginRefreshing()
        }
    }

    func beginRefreshing() {
        guard !isRefreshing else { return }

        isRefreshing = true
        spinner.startAnimating()
        onRefresh?()
    }

    func endRefreshing() {
        isRefreshing = false
        spinner.stopAnimating()
    }
}
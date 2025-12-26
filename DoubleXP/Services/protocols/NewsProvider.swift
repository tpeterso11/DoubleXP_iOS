//
//  NewsProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


protocol NewsProvider {
    func fetchArticles(completion: @escaping ([Article]) -> Void)
}
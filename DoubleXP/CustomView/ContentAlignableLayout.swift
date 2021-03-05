//
//  ContentAlignableLayout.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/27/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation

public enum ContentAlign {
    case left
    case right
}

public class ContentAlignableLayout: BaseLayout {
    public var contentAlign: ContentAlign = .left
}

//
//  RSSParserDelegate.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation

func fetchVideoRSSFeed(urlString: String) {
    guard let url = URL(string: urlString) else { return }
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, error == nil else { return }
        parseRSSFeed(data: data)
    }
    task.resume()
}

func parseRSSFeed(data: Data) {
    let parser = XMLParser(data: data)
    let rssParserDelegate = RSSParserDelegate()
    parser.delegate = rssParserDelegate
    parser.parse()
}

class RSSParserDelegate: NSObject, XMLParserDelegate {
    var currentElement = ""
    var currentTitle = ""
    var currentLink = ""
    var currentMediaURL = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "enclosure", let url = attributeDict["url"] {
            currentMediaURL = url
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            if !currentMediaURL.isEmpty {
                print("Video Title: \(currentTitle)")
                print("Video Link: \(currentLink)")
                print("Video URL: \(currentMediaURL)")
            }
            currentTitle = ""
            currentLink = ""
            currentMediaURL = ""
        }
    }
}
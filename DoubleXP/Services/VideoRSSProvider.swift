//
//  VideoRSSProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation

class VideoRSSProvider: NewsProvider {
    private let feedURL: URL
    private let source: String
    private let cacheManager: JSONCacheManager<Article>

    init(feedURL: URL, source: String) {
        self.feedURL = feedURL
        self.source = source

        // Use a sanitized filename based on host and source
        let safeHost = feedURL.host?.replacingOccurrences(of: ".", with: "_") ?? "rss"
        let fileName = "rss_\(safeHost)_\(source)"
        self.cacheManager = JSONCacheManager<Article>(cacheFileName: fileName)
    }

    func fetchArticles(completion: @escaping ([Article]) -> Void) {
        if let cached = cacheManager.load() {
            completion(cached)
            return
        }

        var request = URLRequest(url: feedURL)
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Failed to fetch RSS feed from \(self.feedURL): \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            let parser = XMLParser(data: data)
            let delegate = VideoRSSParser(source: self.source)
            parser.delegate = delegate
            let success = parser.parse()

            if success {
                let articles = delegate.results
                self.cacheManager.save(articles)
                completion(articles)
            } else {
                print("❌ XML parsing failed for feed: \(self.feedURL)")
                completion([])
            }
        }.resume()
    }
}

class VideoRSSParser: NSObject, XMLParserDelegate {
    private let source: String
    private var articles: [Article] = []
    private var currentElement = ""
    
    private var currentTitle: String?
    private var currentLink: String?
    private var currentDescription: String?
    private var currentImageUrl: String?
    private var currentVideoUrl: String?
    private var currentVideoThumbnailUrl: String?
    private var currentPublishedAt: Date?
    private var currentIsVideo = false

    private var currentContent: String?
    private var isAtomEntry = false

    private let dateFormats = [
        "E, d MMM yyyy HH:mm:ss Z",             // RSS (GameSpot, GameInformer)
        "yyyy-MM-dd'T'HH:mm:ssZ",               // Atom (Polygon)
        "yyyy-MM-dd'T'HH:mm:ssXXX",             // Atom with time zone colon
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    ]

    init(source: String) {
        self.source = source
    }

    var results: [Article] {
        return articles.sorted(by: >)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {

        currentElement = elementName

        if elementName == "item" || elementName == "entry" {
            resetCurrentEntry()
            isAtomEntry = (elementName == "entry")
        }

        if elementName == "media:content", let url = attributeDict["url"] {
            currentImageUrl = url
        }

        if elementName == "link" {
            if isAtomEntry {
                if attributeDict["rel"] == "alternate", let href = attributeDict["href"] {
                    currentLink = href
                }
            } else {
                currentLink = attributeDict["href"] ?? currentLink
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "title":
            currentTitle = (currentTitle ?? "") + trimmed
        case "link":
            if !isAtomEntry {
                currentLink = (currentLink ?? "") + trimmed
            }
        case "description", "summary":
            currentDescription = (currentDescription ?? "") + trimmed
        case "pubDate", "published", "updated":
            currentPublishedAt = parseDate(from: trimmed)
        case "content":
            currentContent = (currentContent ?? "") + trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {

        if elementName == "item" || elementName == "entry" {
            let title = currentTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled"
            let url = currentLink?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let date = currentPublishedAt ?? Date()

            // Fallback: try to get image from embedded content (e.g., <img src="...">)
            let html = currentContent ?? currentDescription ?? ""
            let embeddedImageUrl = extractImageURL(fromHTML: html)
            let videoEmbedUrl = extractYouTubeEmbedURL(fromHTML: html)
            let id = ArticleID.make(
                title: title,
                url: url,
                publishedAt: date,
                source: source
            )

            let article = Article(
                title: title,
                description: currentDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url,
                imageUrl: currentImageUrl ?? embeddedImageUrl,
                publishedAt: date, id: id,
                isVideo: videoEmbedUrl != nil,
                videoUrl: videoEmbedUrl,
                videoThumbnailUrl: videoEmbedUrl != nil ? getYouTubeThumbnail(from: videoEmbedUrl!) : nil,
                source: source
            )

            articles.append(article)
        }
    }

    private func resetCurrentEntry() {
        currentTitle = nil
        currentLink = nil
        currentDescription = nil
        currentImageUrl = nil
        currentVideoUrl = nil
        currentVideoThumbnailUrl = nil
        currentPublishedAt = nil
        currentIsVideo = false
        currentContent = nil
    }

    private func parseDate(from string: String) -> Date? {
        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    private func extractImageURL(fromHTML html: String) -> String? {
        guard let range = html.range(of: "<img[^>]+src=[\"']([^\"']+)[\"']", options: .regularExpression),
              let match = html[range].range(of: "src=[\"']([^\"']+)[\"']", options: .regularExpression) else {
            return nil
        }

        let fullMatch = html[match]
        if let srcRange = fullMatch.range(of: #"src=["']([^"']+)["']"#, options: .regularExpression),
           let urlMatch = html[srcRange].split(separator: "\"").dropFirst().first {
            return String(urlMatch)
        }

        return nil
    }

    private func extractYouTubeEmbedURL(fromHTML html: String) -> String? {
        guard let range = html.range(of: "youtube.com/embed/[^\"']+", options: .regularExpression) else {
            return nil
        }
        return "https://" + html[range]
    }

    private func getYouTubeThumbnail(from videoUrl: String) -> String? {
        guard let videoId = videoUrl.split(separator: "/").last else { return nil }
        return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
    }
}

extension DateFormatter {
    static let rssDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return fmt
    }()
}

//
//  WikidataGameInfo.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/13/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

struct WikidataGameInfo {
    let platforms: [String]
    let genres: [String]
    let developers: [String]
    let publishers: [String]
    let releaseDateISO: String?
    let series: String?
    let officialSite: String?
}

enum WikidataError: Error {
    case notFound, badResponse, badData
}

final class WikidataClient {
    static let shared = WikidataClient()
    private init() {}

    struct WikidataGameInfo {
        let qid: String?
        let label: String?
        let platforms: [String]
        let genres: [String]
        let developers: [String]
        let publishers: [String]
        let releaseDateISO: String?
        let series: String?
        let officialSite: String?
    }

    enum WikidataError: Error {
        case badResponse, notFound
    }

    // MARK: - Public API

    func fetchInfo(title rawTitle: String) async throws -> WikidataGameInfo {
        // Try a few variants to handle curly/straight apostrophes & “video game” disambiguation
        let variants: [String] = {
            let straight = rawTitle.replacingOccurrences(of: "’", with: "'")
            let curly   = rawTitle.replacingOccurrences(of: "'", with: "’")
            return [
                straight,
                curly,
                straight + " (video game)",
                curly   + " (video game)",
                straight + " video game",
                curly   + " video game"
            ]
            .removingDuplicates()
        }()

        // 1) mwapi entity search (best-ordinal), filtered to video games
        for v in variants {
            if let info = try? await fetchViaEntitySearch(v) { return info }
        }

        // 2) fallback: label contains… within video games; pick item with most sitelinks
        for v in variants {
            if let info = try? await fetchViaLabelContains(v) { return info }
        }

        throw WikidataError.notFound
    }

    // MARK: - Core queries

    private func fetchViaEntitySearch(_ title: String) async throws -> WikidataGameInfo {
        let q = sparqlQuote(title)
        let sparql = """
        SELECT
          (STR(?item) AS ?itemIRI)
          ?itemLabel
          (GROUP_CONCAT(DISTINCT ?platformLabel; SEPARATOR="|") AS ?platforms)
          (GROUP_CONCAT(DISTINCT ?genreLabel; SEPARATOR="|")    AS ?genres)
          (GROUP_CONCAT(DISTINCT ?devLabel; SEPARATOR="|")      AS ?developers)
          (GROUP_CONCAT(DISTINCT ?pubLabel; SEPARATOR="|")      AS ?publishers)
          ?releaseDate ?seriesLabel ?officialSite
        WHERE {
          {
            SELECT ?item WHERE {
              SERVICE wikibase:mwapi {
                bd:serviceParam wikibase:endpoint "www.wikidata.org";
                                wikibase:api "EntitySearch";
                                mwapi:search "\(q)";
                                mwapi:language "en".
                ?item wikibase:apiOutputItem mwapi:item.
                ?ordinal wikibase:apiOrdinal true.
              }
              # Only items that are video games
              ?item wdt:P31/wdt:P279* wd:Q7889 .
            }
            ORDER BY ?ordinal
            LIMIT 1
          }

          OPTIONAL { ?item wdt:P400 ?platform . }
          OPTIONAL { ?item wdt:P136 ?genre . }
          OPTIONAL { ?item wdt:P178 ?dev . }
          OPTIONAL { ?item wdt:P123 ?pub . }
          OPTIONAL { ?item wdt:P577 ?releaseDate . }
          OPTIONAL { ?item wdt:P179 ?series . }
          OPTIONAL { ?item wdt:P856 ?officialSite . }

          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
        GROUP BY ?item ?itemLabel ?releaseDate ?seriesLabel ?officialSite
        """

        return try await runAndParse(sparql)
    }

    private func fetchViaLabelContains(_ title: String) async throws -> WikidataGameInfo {
        let qLower = sparqlQuote(title.lowercased())
        let sparql = """
        SELECT
          (STR(?item) AS ?itemIRI)
          ?itemLabel
          (GROUP_CONCAT(DISTINCT ?platformLabel; SEPARATOR="|") AS ?platforms)
          (GROUP_CONCAT(DISTINCT ?genreLabel; SEPARATOR="|")    AS ?genres)
          (GROUP_CONCAT(DISTINCT ?devLabel; SEPARATOR="|")      AS ?developers)
          (GROUP_CONCAT(DISTINCT ?pubLabel; SEPARATOR="|")      AS ?publishers)
          ?releaseDate ?seriesLabel ?officialSite
          (COUNT(?sitelink) AS ?sitelinks)
        WHERE {
          # Video games only
          ?item wdt:P31/wdt:P279* wd:Q7889 .
          ?item rdfs:label ?lbl .
          FILTER (LANG(?lbl) = "en")
          FILTER (CONTAINS(LCASE(?lbl), "\(qLower)"))

          OPTIONAL { ?item wdt:P400 ?platform . }
          OPTIONAL { ?item wdt:P136 ?genre . }
          OPTIONAL { ?item wdt:P178 ?dev . }
          OPTIONAL { ?item wdt:P123 ?pub . }
          OPTIONAL { ?item wdt:P577 ?releaseDate . }
          OPTIONAL { ?item wdt:P179 ?series . }
          OPTIONAL { ?item wdt:P856 ?officialSite . }

          # Count site links as a proxy for prominence
          OPTIONAL { ?sitelink schema:about ?item . }
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
        GROUP BY ?item ?itemLabel ?releaseDate ?seriesLabel ?officialSite
        ORDER BY DESC(?sitelinks)
        LIMIT 1
        """

        return try await runAndParse(sparql)
    }

    // MARK: - Transport + parsing

    private func runAndParse(_ sparql: String) async throws -> WikidataGameInfo {
        var comps = URLComponents(string: "https://query.wikidata.org/sparql")!
        comps.queryItems = [
            .init(name: "format", value: "json"),
            .init(name: "query", value: sparql)
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("application/sparql-results+json", forHTTPHeaderField: "Accept")
        req.setValue("DoubleXP/1.0 (Wikidata enrichment; contact: support@doublexp.example)", forHTTPHeaderField: "User-Agent")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw WikidataError.badResponse }

        struct Root: Decodable {
            struct Results: Decodable {
                struct V: Decodable { let value: String }
                struct Binding: Decodable {
                    let itemIRI: V?
                    let itemLabel: V?
                    let platforms: V?
                    let genres: V?
                    let developers: V?
                    let publishers: V?
                    let releaseDate: V?
                    let seriesLabel: V?
                    let officialSite: V?
                }
                let bindings: [Binding]
            }
            let results: Results
        }

        let root = try JSONDecoder().decode(Root.self, from: data)
        guard let row = root.results.bindings.first else { throw WikidataError.notFound }

        func split(_ v: Root.Results.V?) -> [String] {
            v?.value.split(separator: "|").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
        }

        let qid: String? = {
            guard let iri = row.itemIRI?.value else { return nil }
            return iri.components(separatedBy: "/").last
        }()

        return WikidataGameInfo(
            qid: qid,
            label: row.itemLabel?.value,
            platforms: split(row.platforms),
            genres: split(row.genres),
            developers: split(row.developers),
            publishers: split(row.publishers),
            releaseDateISO: row.releaseDate?.value,
            series: row.seriesLabel?.value,
            officialSite: row.officialSite?.value
        )
    }

    // Proper SPARQL literal escaping for "..." strings
    private func sparqlQuote(_ s: String) -> String {
        s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

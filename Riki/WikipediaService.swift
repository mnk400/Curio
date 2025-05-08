//
//  WikipediaService.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import Foundation
import Combine
import SwiftSoup

class WikipediaService {
    static let shared = WikipediaService()
    
    private init() {}
    
    func fetchRandomArticle() -> AnyPublisher<WikiArticle, Error> {
        return fetchRandomArticleSummary()
            .flatMap { summaryResponse -> AnyPublisher<WikiArticle, Error> in
                self.fetchFullArticleContent(for: summaryResponse)
                    .map { sections -> WikiArticle in
                        self.createArticleFromSummary(summaryResponse, sections: sections)
                    }
                    .catch { error -> AnyPublisher<WikiArticle, Error> in
                        // If fetching full content fails, return an article with just the summary
                        print("Error fetching full article content: \(error). Falling back to summary.")
                        return Just(self.createArticleFromSummary(summaryResponse, sections: []))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func fetchRandomArticleSummary() -> AnyPublisher<WikipediaDetailResponse, Error> {
        let randomSummaryURL = "https://en.wikipedia.org/api/rest_v1/page/random/summary"
        
        guard let url = URL(string: randomSummaryURL) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: WikipediaDetailResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    private func fetchFullArticleContent(for summaryResponse: WikipediaDetailResponse) -> AnyPublisher<[ArticleSection], Error> {
        let title = summaryResponse.title
        let parseAPIURLString = "https://en.wikipedia.org/w/api.php?action=parse&page=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&prop=text&format=json&origin=*"
        
        guard let fullContentURL = URL(string: parseAPIURLString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: fullContentURL)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .tryMap { data -> [ArticleSection] in
                return try self.parseArticleContentResponse(data: data)
            }
            .eraseToAnyPublisher()
    }

    private func parseArticleContentResponse(data: Data) throws -> [ArticleSection] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let parseData = json?["parse"] as? [String: Any],
              let textData = parseData["text"] as? [String: Any],
              let htmlContent = textData["*"] as? String else {
            // If parsing fails, return empty sections, the caller will handle fallback.
            return [] 
        }
        
        return self.parseHTMLContent(htmlContent)
    }
    
    // Helper method to create a WikiArticle from a summary response
    private func createArticleFromSummary(_ response: WikipediaDetailResponse, sections: [ArticleSection]) -> WikiArticle {
        let dateFormatter = ISO8601DateFormatter()
        let lastModified = response.lastmodified != nil ? dateFormatter.date(from: response.lastmodified!) : nil
        
        let finalSections = sections.isEmpty ? [ArticleSection(title: "", level: 0, content: response.extract)] : sections
        
        return WikiArticle(
            id: response.id,
            title: response.title,
            extract: response.extract,
            content: "",
            thumbnail: response.thumbnail?.source,
            url: response.content_urls.mobile.page,
            lastModified: lastModified,
            sections: finalSections
        )
    }
    
    private func parseHTMLContent(_ htmlString: String) -> [ArticleSection] {
        var sections: [ArticleSection] = []
        do {
            let doc = try SwiftSoup.parse(htmlString)

            let unwantedSelectors = [
            ".infobox", ".thumb", ".toc", ".mw-editsection",
            ".navbox", ".metadata", "table", ".mw-empty-elt",
            ".mw-jump-link", ".mw-parser-output > style",
            "img", ".image", ".mbox", ".ambox", ".tmbox",
            ".vertical-navbox", ".sistersitebox", ".wikitable"
            ]
            for selector in unwantedSelectors {
                try doc.select(selector).remove()
            }
            
            guard let content = try doc.select(".mw-parser-output").first() ?? doc.body() else {
                return [ArticleSection(title: "Error", level: 0, content: "Could not find main content area.")]
            }
            
            if let introSection = try extractIntroduction(from: content) {
                sections.append(introSection)
            }
            
            sections.append(contentsOf: try extractSectionsFromHeadings(in: content))
            
            if sections.isEmpty {
                let bodyText = try doc.body()?.text() ?? ""
                if !bodyText.isEmpty {
                    sections.append(ArticleSection(title: "", level: 0, content: bodyText))
                }
            }
        } catch {
            print("Error parsing HTML: \(error)")
            sections.append(ArticleSection(title: "Error", level: 0, content: "Could not parse article content."))
        }
        return sections
    }

    private func extractIntroduction(from content: Element) throws -> ArticleSection? {
        var introText = ""
        for element in try content.children() {
            let tagName = try element.tagName().lowercased()
            if tagName.starts(with: "h") { // Stop if a heading is encountered
                break
            }
            if !tagName.isEmpty {
                 let elementText = try element.text()
                 if !elementText.isEmpty {
                     introText += elementText + "\n\n"
                 }
            }
        }
        let trimmedIntro = introText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedIntro.isEmpty ? nil : ArticleSection(title: "", level: 2, content: trimmedIntro)
    }

    private func extractSectionsFromHeadings(in content: Element) throws -> [ArticleSection] {
        var extractedSections: [ArticleSection] = []
        let headings = try content.select("h1, h2, h3, h4, h5, h6")
        
        for i in 0..<headings.size() {
            let heading = try headings.get(i)
            let headingTag = try heading.tagName().lowercased()
            guard let level = Int(headingTag.dropFirst()) else { continue } // h1 -> 1
            let title = try heading.text()
            
            var sectionContent = ""
            var nextElement = try heading.nextElementSibling()
            
            while let currentElement = nextElement {
                let currentTagName = try currentElement.tagName().lowercased()
                // Stop if another heading of the same or higher level is encountered
                if currentTagName.starts(with: "h") {
                    if let nextLevel = Int(currentTagName.dropFirst()), nextLevel <= level {
                        break
                    }
                }
                
                let elementText = try currentElement.text()
                if !elementText.isEmpty {
                    sectionContent += elementText + "\n\n"
                }
                nextElement = try currentElement.nextElementSibling()
            }
            
            let trimmedSectionContent = sectionContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSectionContent.isEmpty {
                extractedSections.append(ArticleSection(
                    title: title,
                    level: level,
                    content: trimmedSectionContent
                ))
            }
        }
        return extractedSections
    }
}

struct ContentURLs: Codable {
    let mobile: MobileURL
}

struct MobileURL: Codable {
    let page: URL
}

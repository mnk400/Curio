//
//  WikipediaService.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import Foundation
import SwiftSoup

// MARK: - Custom Errors
enum WikipediaError: LocalizedError {
    case invalidURL
    case noData
    case parsingError(String)
    case networkError(Error)
    case articleNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Wikipedia URL"
        case .noData:
            return "No data received from Wikipedia"
        case .parsingError(let message):
            return "Failed to parse article: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .articleNotFound:
            return "Article not found"
        }
    }
}

// MARK: - Wikipedia Service
@MainActor
class WikipediaService {
    static let shared = WikipediaService()
    
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.jsonDecoder = JSONDecoder()
    }
    
    func fetchRandomArticle() async throws -> WikiArticle {
        // First, get a random article summary
        let summaryResponse = try await fetchRandomArticleSummary()
        
        // Then, try to fetch full content
        do {
            let sections = try await fetchFullArticleContent(for: summaryResponse)
            return createArticleFromSummary(summaryResponse, sections: sections)
        } catch {
            // If fetching full content fails, return an article with just the summary
            print("Warning: Failed to fetch full article content: \(error). Using summary only.")
            return createArticleFromSummary(summaryResponse, sections: [])
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchRandomArticleSummary() async throws -> WikipediaDetailResponse {
        let randomSummaryURL = "https://en.wikipedia.org/api/rest_v1/page/random/summary"
        
        guard let url = URL(string: randomSummaryURL) else {
            throw WikipediaError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WikipediaError.networkError(URLError(.badServerResponse))
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WikipediaError.networkError(URLError(.badServerResponse))
            }
            
            guard !data.isEmpty else {
                throw WikipediaError.noData
            }
            
            return try jsonDecoder.decode(WikipediaDetailResponse.self, from: data)
            
        } catch let decodingError as DecodingError {
            throw WikipediaError.parsingError("Failed to decode summary: \(decodingError.localizedDescription)")
        } catch {
            throw WikipediaError.networkError(error)
        }
    }
    
    private func fetchFullArticleContent(for summaryResponse: WikipediaDetailResponse) async throws -> [ArticleSection] {
        let title = summaryResponse.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let parseAPIURLString = "https://en.wikipedia.org/w/api.php?action=parse&page=\(title)&prop=text&format=json&origin=*"
        
        guard let fullContentURL = URL(string: parseAPIURLString) else {
            throw WikipediaError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: fullContentURL)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WikipediaError.networkError(URLError(.badServerResponse))
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WikipediaError.networkError(URLError(.badServerResponse))
            }
            
            guard !data.isEmpty else {
                throw WikipediaError.noData
            }
            
            return try parseArticleContentResponse(data: data)
            
        } catch let error as WikipediaError {
            throw error
        } catch {
            throw WikipediaError.networkError(error)
        }
    }
    
    private func parseArticleContentResponse(data: Data) throws -> [ArticleSection] {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let parseData = json["parse"] as? [String: Any],
                  let textData = parseData["text"] as? [String: Any],
                  let htmlContent = textData["*"] as? String else {
                throw WikipediaError.parsingError("Invalid JSON structure")
            }
            
            return parseHTMLContent(htmlContent)
            
        } catch {
            throw WikipediaError.parsingError("Failed to parse JSON: \(error.localizedDescription)")
        }
    }
    
    private func createArticleFromSummary(_ response: WikipediaDetailResponse, sections: [ArticleSection]) -> WikiArticle {
        let dateFormatter = ISO8601DateFormatter()
        let lastModified = response.lastmodified.flatMap { dateFormatter.date(from: $0) }
        
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
    
    // MARK: - HTML Parsing
    
    private func parseHTMLContent(_ htmlString: String) -> [ArticleSection] {
        var sections: [ArticleSection] = []
        
        do {
            let doc = try SwiftSoup.parse(htmlString)
            
            // Remove unwanted elements for cleaner content
            let unwantedSelectors = [
                ".infobox", ".thumb", ".toc", ".mw-editsection",
                ".navbox", ".metadata", "table:not(.wikitable)", ".mw-empty-elt",
                ".mw-jump-link", ".mw-parser-output > style",
                "img", ".image", ".mbox", ".ambox", ".tmbox",
                ".vertical-navbox", ".sistersitebox", ".shortdescription",
                ".hatnote", ".dablink", ".rellink", ".magnify"
            ]
            
            for selector in unwantedSelectors {
                try doc.select(selector).remove()
            }
            
            guard let content = try doc.select(".mw-parser-output").first() ?? doc.body() else {
                return [ArticleSection(title: "Error", level: 0, content: "Could not find main content area.")]
            }
            
            // Extract introduction
            if let introSection = try extractIntroduction(from: content) {
                sections.append(introSection)
            }
            
            // Extract sections from headings
            sections.append(contentsOf: try extractSectionsFromHeadings(in: content))
            
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
            
            // Stop at first heading
            if isHeadingElement(element) {
                break
            }
            
            // Skip non-content elements
            if try shouldSkipElement(element) {
                continue
            }
            
            let elementText = try formatElementContent(element)
            if !elementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                introText += elementText + "\n"
            }
        }
        
        let trimmedIntro = introText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedIntro.isEmpty ? nil : ArticleSection(title: "", level: 0, content: trimmedIntro)
    }
    
    private func extractSectionsFromHeadings(in content: Element) throws -> [ArticleSection] {
        var sections: [ArticleSection] = []
        var currentSectionTitle: String?
        var currentSectionLevel: Int?
        var currentSectionContent = ""
        var pastIntroPhase = false
        
        func finalizeCurrentSection() {
            if let title = currentSectionTitle, let level = currentSectionLevel {
                let trimmedContent = currentSectionContent.trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty || !trimmedContent.isEmpty {
                    sections.append(ArticleSection(title: title, level: level, content: trimmedContent))
                }
            }
            currentSectionTitle = nil
            currentSectionLevel = nil
            currentSectionContent = ""
        }
        
        for element in try content.children() {
            if let (level, title) = try extractHeadingInfo(from: element) {
                if !pastIntroPhase {
                    pastIntroPhase = true
                }
                
                finalizeCurrentSection()
                currentSectionTitle = title
                currentSectionLevel = level
                
            } else if pastIntroPhase, currentSectionTitle != nil {
                if try !shouldSkipElement(element) {
                    let elementText = try formatElementContent(element)
                    if !elementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        currentSectionContent += elementText + "\n"
                    }
                }
            }
        }
        
        finalizeCurrentSection()
        return sections
    }
    
    // MARK: - Helper Methods
    
    private func isHeadingElement(_ element: Element) -> Bool {
        do {
            let tagName = try element.tagName().lowercased()
            if tagName.starts(with: "h") && tagName.count == 2 && Int(String(tagName.dropFirst())) != nil {
                return true
            }
            
            if let hTag = try element.select("h1, h2, h3, h4, h5, h6").first() {
                let isParent = element == hTag.parent()
                let hasHeadingClass = try element.hasClass("mw-heading")
                return isParent || hasHeadingClass
            }
            
            return false
        } catch {
            return false
        }
    }
    
    private func extractHeadingInfo(from element: Element) throws -> (level: Int, title: String)? {
        let tagName = try element.tagName().lowercased()
        
        if tagName.starts(with: "h") && tagName.count == 2, let level = Int(String(tagName.dropFirst())) {
            return (level, try element.text())
        }
        
        if let hTag = try element.select("h1, h2, h3, h4, h5, h6").first() {
            let hTagName = try hTag.tagName().lowercased()
            if let level = Int(String(hTagName.dropFirst())) {
                return (level, try hTag.text())
            }
        }
        
        return nil
    }
    
    private func shouldSkipElement(_ element: Element) throws -> Bool {
        let skipClasses = ["shortdescription", "hatnote", "mw-jump-link", "toc", "infobox", "navbox"]
        let skipTags = ["meta", "style"]
        
        let tagName = try element.tagName().lowercased()
        if skipTags.contains(tagName) {
            return true
        }
        
        for skipClass in skipClasses {
            let hasClass = try element.hasClass(skipClass)
            let containsClass = try element.className().contains(skipClass)
            if hasClass || containsClass {
                return true
            }
        }
        
        return false
    }
    
    private func formatElementContent(_ element: Element) throws -> String {
        let tagName = try element.tagName().lowercased()
        
        switch tagName {
        case "ul":
            return try formatUnorderedList(element)
        case "ol":
            return try formatOrderedList(element)
        case "table":
            if try element.hasClass("wikitable") {
                return try formatTable(element)
            }
            return try element.text()
        default:
            return try element.text()
        }
    }
    
    private func formatUnorderedList(_ element: Element) throws -> String {
        var formattedList = ""
        for listItem in try element.select("li") {
            formattedList += "• " + (try listItem.text()) + "\n"
        }
        return formattedList
    }
    
    private func formatOrderedList(_ element: Element) throws -> String {
        var formattedList = ""
        let listItems = try element.select("li")
        for (index, listItem) in listItems.enumerated() {
            formattedList += "\(index + 1). " + (try listItem.text()) + "\n"
        }
        return formattedList
    }
    
    private func formatTable(_ element: Element) throws -> String {
        var tableData: [[String]] = []
        
        // Process header row
        if let headerRow = try element.select("tr").first() {
            var headers: [String] = []
            for header in try headerRow.select("th") {
                headers.append(try header.text().trimmingCharacters(in: .whitespacesAndNewlines))
            }
            if !headers.isEmpty {
                tableData.append(headers)
            }
        }
        
        // Process data rows
        for row in try element.select("tr").dropFirst() {
            var rowData: [String] = []
            for cell in try row.select("td") {
                rowData.append(try cell.text().trimmingCharacters(in: .whitespacesAndNewlines))
            }
            if !rowData.isEmpty {
                tableData.append(rowData)
            }
        }
        
        // Convert table data to string representation
        if !tableData.isEmpty {
            return "<table>" + tableData.map { row in row.joined(separator: "\t") }.joined(separator: "\n") + "</table>"
        }
        
        return ""
    }
}

// MARK: - Response Models

struct ContentURLs: Codable {
    let mobile: MobileURL
}

struct MobileURL: Codable {
    let page: URL
}

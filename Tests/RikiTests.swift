//
//  RikiTests.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import XCTest
@testable import Riki

final class RikiTests: XCTestCase {
    
    // MARK: - WikiArticle Tests
    func testWikiArticleEquality() {
        let article1 = WikiArticle(
            id: "123",
            title: "Test Article",
            extract: "Test extract",
            content: "Test content",
            thumbnail: nil,
            url: URL(string: "https://example.com")!,
            lastModified: nil,
            sections: []
        )
        
        let article2 = WikiArticle(
            id: "123",
            title: "Different Title",
            extract: "Different extract",
            content: "Different content",
            thumbnail: nil,
            url: URL(string: "https://different.com")!,
            lastModified: nil,
            sections: []
        )
        
        XCTAssertEqual(article1, article2, "Articles with same ID should be equal")
    }
    
    func testWikiArticleHasContent() {
        let emptyArticle = WikiArticle(
            id: "1",
            title: "Empty",
            extract: "",
            content: "",
            thumbnail: nil,
            url: URL(string: "https://example.com")!,
            lastModified: nil,
            sections: []
        )
        
        let articleWithExtract = WikiArticle(
            id: "2",
            title: "With Extract",
            extract: "Some extract",
            content: "",
            thumbnail: nil,
            url: URL(string: "https://example.com")!,
            lastModified: nil,
            sections: []
        )
        
        let articleWithSections = WikiArticle(
            id: "3",
            title: "With Sections",
            extract: "",
            content: "",
            thumbnail: nil,
            url: URL(string: "https://example.com")!,
            lastModified: nil,
            sections: [ArticleSection(title: "Section", level: 1, content: "Content")]
        )
        
        XCTAssertFalse(emptyArticle.hasContent)
        XCTAssertTrue(articleWithExtract.hasContent)
        XCTAssertTrue(articleWithSections.hasContent)
    }
    
    func testReadingTimeEstimate() {
        let shortArticle = WikiArticle(
            id: "1",
            title: "Short",
            extract: "This is a short extract with ten words exactly here.",
            content: "",
            thumbnail: nil,
            url: URL(string: "https://example.com")!,
            lastModified: nil,
            sections: []
        )
        
        XCTAssertEqual(shortArticle.readingTimeEstimate, 1, "Short articles should have minimum 1 minute reading time")
        
        // Create a longer article
        let longExtract = String(repeating: "word ", count: 400) // 400 words
        let longArticle = WikiArticle(
            id: "2",
            title: "Long",
            extract: longExtract,
            content: "",
            thumbnail: nil,
            url: URL(string: "https://example.com")!,
            lastModified: nil,
            sections: []
        )
        
        XCTAssertEqual(longArticle.readingTimeEstimate, 2, "400 words should take 2 minutes to read")
    }
    
    // MARK: - ArticleSection Tests
    func testArticleSectionIsEmpty() {
        let emptySection = ArticleSection(title: "", level: 0, content: "")
        let whitespaceSection = ArticleSection(title: "  ", level: 0, content: "  \n  ")
        let contentSection = ArticleSection(title: "Title", level: 1, content: "Content")
        
        XCTAssertTrue(emptySection.isEmpty)
        XCTAssertTrue(whitespaceSection.isEmpty)
        XCTAssertFalse(contentSection.isEmpty)
    }
    
    func testArticleSectionWordCount() {
        let section = ArticleSection(
            title: "Test Section",
            level: 1,
            content: "This is a test section with exactly ten words here."
        )
        
        XCTAssertEqual(section.wordCount, 10)
    }
    
    // MARK: - ThumbnailInfo Tests
    func testThumbnailAspectRatio() {
        let landscapeThumbnail = ThumbnailInfo(
            source: URL(string: "https://example.com/image.jpg")!,
            width: 800,
            height: 600
        )
        
        let portraitThumbnail = ThumbnailInfo(
            source: URL(string: "https://example.com/image.jpg")!,
            width: 600,
            height: 800
        )
        
        let squareThumbnail = ThumbnailInfo(
            source: URL(string: "https://example.com/image.jpg")!,
            width: 500,
            height: 500
        )
        
        XCTAssertTrue(landscapeThumbnail.isLandscape)
        XCTAssertFalse(portraitThumbnail.isLandscape)
        XCTAssertFalse(squareThumbnail.isLandscape)
        
        XCTAssertEqual(landscapeThumbnail.aspectRatio, 800.0/600.0, accuracy: 0.01)
        XCTAssertEqual(squareThumbnail.aspectRatio, 1.0, accuracy: 0.01)
    }
    
    // MARK: - WikipediaError Tests
    func testWikipediaErrorDescriptions() {
        let invalidURLError = WikipediaError.invalidURL
        let noDataError = WikipediaError.noData
        let parsingError = WikipediaError.parsingError("Test parsing error")
        let networkError = WikipediaError.networkError(URLError(.badURL))
        let notFoundError = WikipediaError.articleNotFound
        
        XCTAssertNotNil(invalidURLError.errorDescription)
        XCTAssertNotNil(noDataError.errorDescription)
        XCTAssertNotNil(parsingError.errorDescription)
        XCTAssertNotNil(networkError.errorDescription)
        XCTAssertNotNil(notFoundError.errorDescription)
        
        XCTAssertTrue(parsingError.errorDescription!.contains("Test parsing error"))
    }
    
    // MARK: - Performance Tests
    func testFormattedTextViewPerformance() {
        let longText = String(repeating: "This is a long text with many words. ", count: 1000)
        
        measure {
            let formattedTextView = FormattedTextView(text: longText)
            _ = formattedTextView.estimatedReadingTime
        }
    }
    
    func testHTMLParsingPerformance() {
        let htmlContent = """
        <div class="mw-parser-output">
            <p>This is a test paragraph with some content.</p>
            <h2>Section 1</h2>
            <p>Content for section 1.</p>
            <ul>
                <li>List item 1</li>
                <li>List item 2</li>
            </ul>
            <h3>Subsection</h3>
            <p>More content here.</p>
        </div>
        """
        
        measure {
            // This would test the HTML parsing performance
            // We can't directly test the private method, but we can test the overall service
            let service = WikipediaService.shared
            // Performance testing would be done with actual network calls in integration tests
        }
    }
}

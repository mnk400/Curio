//
//  CurioTests.swift
//  Curio
//
//  Created by Manik on 5/1/25.
//

import XCTest
@testable import Curio

final class CurioTests: XCTestCase {

    // MARK: - WikiArticle Tests
    func testWikiArticleEquality() {
        let article1 = WikiArticle(
            id: "123",
            title: "Test Article",
            extract: "Test extract",
            thumbnail: nil,
            imageWidth: nil,
            imageHeight: nil,
            url: URL(string: "https://example.com")!
        )

        let article2 = WikiArticle(
            id: "123",
            title: "Different Title",
            extract: "Different extract",
            thumbnail: nil,
            imageWidth: nil,
            imageHeight: nil,
            url: URL(string: "https://different.com")!
        )

        XCTAssertEqual(article1, article2, "Articles with same ID should be equal")
    }

    func testWikiArticleHasContent() {
        let emptyArticle = WikiArticle(
            id: "1",
            title: "Empty",
            extract: "",
            thumbnail: nil,
            imageWidth: nil,
            imageHeight: nil,
            url: URL(string: "https://example.com")!
        )

        let articleWithExtract = WikiArticle(
            id: "2",
            title: "With Extract",
            extract: "Some extract",
            thumbnail: nil,
            imageWidth: nil,
            imageHeight: nil,
            url: URL(string: "https://example.com")!
        )

        XCTAssertFalse(emptyArticle.hasContent)
        XCTAssertTrue(articleWithExtract.hasContent)
    }

    func testWikiArticleIsHighResImage() {
        let highRes = WikiArticle(
            id: "1",
            title: "High Res",
            extract: "",
            thumbnail: URL(string: "https://example.com/img.jpg"),
            imageWidth: 1200,
            imageHeight: 900,
            url: URL(string: "https://example.com")!
        )

        let lowRes = WikiArticle(
            id: "2",
            title: "Low Res",
            extract: "",
            thumbnail: URL(string: "https://example.com/img.jpg"),
            imageWidth: 400,
            imageHeight: 300,
            url: URL(string: "https://example.com")!
        )

        let noImage = WikiArticle(
            id: "3",
            title: "No Image",
            extract: "",
            thumbnail: nil,
            imageWidth: nil,
            imageHeight: nil,
            url: URL(string: "https://example.com")!
        )

        XCTAssertTrue(highRes.isHighResImage)
        XCTAssertFalse(lowRes.isHighResImage)
        XCTAssertFalse(noImage.isHighResImage)
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
}

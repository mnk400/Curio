//
//  FormattedTextView.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import SwiftUI

// MARK: - Table View Component
struct TableView: View {
    let rows: [[String]]
    
    var body: some View {
        if rows.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: 0) {
                            ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                                Text(rows[rowIndex][colIndex])
                                    .font(.system(size: 14, design: .rounded))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(minWidth: 80, alignment: .leading)
                                    .background(
                                        rowIndex == 0 ? 
                                        Color(.systemGray5) : 
                                        (rowIndex % 2 == 0 ? Color(.systemBackground) : Color(.systemGray6))
                                    )
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Table with \(rows.count) rows")
        }
    }
}

// MARK: - Formatted Text View
struct FormattedTextView: View {
    let text: String
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    
    init(text: String, fontSize: CGFloat = 16, lineSpacing: CGFloat = 5) {
        self.text = text
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
    }
    
    var body: some View {
        let components = parseComponents(text)
        
        if components.isEmpty {
            Text("No content available")
                .font(.system(size: fontSize))
                .foregroundColor(.secondary)
                .italic()
        } else {
            LazyVStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(components.indices, id: \.self) { index in
                    switch components[index] {
                    case .text(let content):
                        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(formatText(content))
                                .font(.system(size: fontSize, design: .default))
                                .lineSpacing(lineSpacing)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.leading)
                                .accessibilityElement(children: .combine)
                        }
                    case .table(let rows):
                        TableView(rows: rows)
                    }
                }
            }
        }
    }
    
    // MARK: - Component Types
    enum Component {
        case text(String)
        case table([[String]])
    }
    
    // MARK: - Text Processing
    private func parseComponents(_ input: String) -> [Component] {
        guard !input.isEmpty else { return [] }
        
        var components: [Component] = []
        let parts = input.components(separatedBy: "<table>")
        
        for (index, part) in parts.enumerated() {
            if index == 0 {
                let cleanedPart = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedPart.isEmpty {
                    components.append(.text(cleanedPart))
                }
                continue
            }
            
            if let tableEndIndex = part.range(of: "</table>")?.lowerBound {
                let tableContent = String(part[..<tableEndIndex])
                let rows = parseTableContent(tableContent)
                
                if !rows.isEmpty {
                    components.append(.table(rows))
                }
                
                let remainingText = String(part[part.index(after: tableEndIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainingText.isEmpty {
                    components.append(.text(remainingText))
                }
            } else {
                let cleanedPart = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedPart.isEmpty {
                    components.append(.text(cleanedPart))
                }
            }
        }
        
        return components
    }
    
    private func parseTableContent(_ content: String) -> [[String]] {
        let rows = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { row in
                row.components(separatedBy: "\t")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
            .filter { !$0.isEmpty }
        
        return rows
    }
    
    private func formatText(_ input: String) -> String {
        let htmlEntities: [String: String] = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&cent;": "¢",
            "&pound;": "£",
            "&yen;": "¥",
            "&euro;": "€",
            "&copy;": "©",
            "&reg;": "®",
            "&trade;": "™"
        ]
        
        var formatted = input
        
        // Replace HTML entities
        for (entity, replacement) in htmlEntities {
            formatted = formatted.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Remove remaining HTML tags
        formatted = formatted.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Clean up excessive whitespace
        formatted = formatted.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        // Clean up multiple newlines
        formatted = formatted.replacingOccurrences(
            of: "\n\\s*\n\\s*\n",
            with: "\n\n",
            options: .regularExpression
        )
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Extensions
extension FormattedTextView {
    // Create attributed text for future rich text features
    func attributedText(_ input: String) -> AttributedString {
        var attributedString = AttributedString(formatText(input))
        
        // Add basic styling
        attributedString.font = .system(size: fontSize)
        
        return attributedString
    }
    
    // Estimate reading time for the text
    var estimatedReadingTime: Int {
        let wordCount = text.split(separator: " ").count
        return max(1, wordCount / 200) // 200 words per minute average
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            FormattedTextView(
                text: "This is a sample Wikipedia article with some content and a table below.\n\n<table>Name\tAge\tCity\nJohn Doe\t30\tNew York\nJane Smith\t25\tLos Angeles</table>\n\nThis text comes after the table.",
                fontSize: 16,
                lineSpacing: 6
            )
            
            FormattedTextView(
                text: "Simple text without any special formatting or tables.",
                fontSize: 14,
                lineSpacing: 4
            )
        }
        .padding()
    }
}

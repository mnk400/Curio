//
//  FormattedTextView.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import SwiftUI

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
        Text(formatText(text))
            .font(.system(size: fontSize))
            .lineSpacing(lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // Format text by removing any remaining HTML tags and normalizing whitespace
    private func formatText(_ input: String) -> String {
        let formatted = input
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Extension to handle attributed text if needed in the future
extension FormattedTextView {
    func attributedText(_ input: String) -> AttributedString {
        let attributedString = AttributedString(input)
        return attributedString
    }
}

#Preview {
    FormattedTextView(text: "This is a sample Wikipedia article with some **bold** and *italic* text.")
        .padding()
}

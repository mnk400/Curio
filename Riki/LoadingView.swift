//
//  LoadingView.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import SwiftUI

/// A loading view that displays an animated spinner with descriptive text
struct LoadingView: View {
    
    // MARK: - State
    
    @State private var isAnimating = false
    
    // MARK: - Constants
    
    private enum Constants {
        static let spinnerSize: CGFloat = 50
        static let spinnerLineWidth: CGFloat = 4
        static let animationDuration: Double = 1.0
        static let spinnerTrimEnd: CGFloat = 0.7
        static let contentSpacing: CGFloat = 20
        static let textSpacing: CGFloat = 8
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Constants.contentSpacing) {
            animatedSpinner
            loadingTextContent
        }
        .padding()
        .onAppear {
            startAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading Wikipedia article")
    }
    
    // MARK: - Private Views
    
    /// Animated circular loading spinner
    private var animatedSpinner: some View {
        ZStack {
            backgroundCircle
            animatedCircle
        }
    }
    
    /// Background circle for the spinner
    private var backgroundCircle: some View {
        Circle()
            .stroke(Color.gray.opacity(0.3), lineWidth: Constants.spinnerLineWidth)
            .frame(width: Constants.spinnerSize, height: Constants.spinnerSize)
    }
    
    /// Animated foreground circle
    private var animatedCircle: some View {
        Circle()
            .trim(from: 0, to: Constants.spinnerTrimEnd)
            .stroke(
                Color.blue,
                style: StrokeStyle(lineWidth: Constants.spinnerLineWidth, lineCap: .round)
            )
            .frame(width: Constants.spinnerSize, height: Constants.spinnerSize)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: Constants.animationDuration)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
    }
    
    /// Text content describing the loading state
    private var loadingTextContent: some View {
        VStack(spacing: Constants.textSpacing) {
            Text("Discovering Wikipedia")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Finding an interesting article for you...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts the loading animation
    private func startAnimation() {
        isAnimating = true
    }
}

#Preview {
    LoadingView()
}
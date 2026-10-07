import SwiftUI
import UIKit

/// Feedback is its own path, never a branch of a rating question. Guideline
/// 5.6.1 rejects asking "Enjoying it?" and sending only the yes answers to the
/// App Store, so ratings go straight to Apple's own prompt and this sheet only
/// collects feedback, opened from Settings.
@MainActor
final class ReviewPromptCoordinator: ObservableObject {
    static let shared = ReviewPromptCoordinator()

    @Published var feedbackRequested = false

    private init() {}

    func requestFeedback() {
        feedbackRequested = true
    }

    func clear() {
        feedbackRequested = false
    }
}

enum ReviewPromptDismissOutcome: Sendable {
    case notNow
    case feedbackSubmitted
}

struct ReviewPromptSheet: View {
    let onFinish: (ReviewPromptDismissOutcome) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var mailFailed = false
    @FocusState private var feedbackFocused: Bool

    var body: some View {
        NavigationStack {
            feedbackContent
                .navigationTitle("Help us improve")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Not now") { finish(.notNow) }
                    }
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var feedbackContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What would make Protein Tracker work better for you?")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $feedbackText)
                .font(.system(.body, design: .rounded))
                .frame(minHeight: 140)
                .padding(10)
                .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 12))
                .focused($feedbackFocused)
                // The prompt above is not programmatically attached to the
                // editor, so without this VoiceOver reaches an unnamed field.
                .accessibilityLabel("Your feedback")
                .accessibilityHint("What would make Protein Tracker work better for you")

            if mailFailed {
                Text("No mail app could be opened. Your words are still here. Copy them into an email to \(Self.feedbackAddress).")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.coral)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Opens your mail app with a draft to the developer. No analytics, just your words.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            Button {
                sendFeedback()
            } label: {
                primaryButtonLabel("Send feedback")
            }
            .buttonStyle(.plain)
            .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .onAppear { feedbackFocused = true }
    }

    private func primaryButtonLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.proteinGradient, in: Capsule())
    }

    /// Feedback is only "submitted" once iOS has actually handed the draft to a
    /// mail client. A device with no mail app configured otherwise closed the
    /// sheet, dropped the typed text, and reported success.
    private func sendFeedback() {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = Self.feedbackMailURL(body: trimmed) else { return }
        UIApplication.shared.open(url, options: [:]) { opened in
            Task { @MainActor in
                guard opened else {
                    mailFailed = true
                    return
                }
                ReviewPromptTracker.markFeedbackSubmitted()
                finish(.feedbackSubmitted)
            }
        }
    }

    private func finish(_ outcome: ReviewPromptDismissOutcome) {
        onFinish(outcome)
        dismiss()
    }

    static let feedbackAddress = "jackwallner+protein@gmail.com"

    /// Pre-filled mailto for private, account-free feedback.
    static func feedbackMailURL(body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackAddress
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Protein Tracker feedback"),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}

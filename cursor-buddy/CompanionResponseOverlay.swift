//
//  CompanionResponseOverlay.swift
//  cursor-buddy
//
//  Streaming reply beside the AI pointer, dismissed manually with Esc or ×.
//  A non-activating panel keeps the underlying app in focus.
//

import AppKit
import Combine
import SwiftUI
#if DEBUG
import ScreenCaptureKit
#endif

// MARK: - View Model

@MainActor
final class CompanionResponseOverlayViewModel: ObservableObject {
    @Published var streamingResponseText: String = ""
    @Published var isShowingResponse: Bool = false
    @Published var isHovered = false
    weak var companion: CompanionManager?
}

// MARK: - Overlay Manager

@MainActor
final class CompanionResponseOverlayManager {
    private let overlayViewModel = CompanionResponseOverlayViewModel()
    private var overlayPanel: NSPanel?
    private var responseHostingView: NSView?
    private var updateHostingWidth: ((CGFloat) -> Void)?
    #if DEBUG
    private var debugAnchorSamplesRemaining = 0
    private var debugLastAnchorSampleAt: TimeInterval = 0
    #endif
    private var cursorTrackingTimer: Timer?
    private var lastCursorTrackingOrigin: NSPoint?
    private var visibilityPolicy = ReplyVisibilityPolicy()
    /// True until dismissal or replacement by a new question.
    private(set) var isVisible: Bool = false
    /// Optional callback when the bubble hides.
    var onHidden: (() -> Void)?

    /// Maximum width of the overlay panel.
    private let overlayMaxWidth: CGFloat = 360

    func bind(companion: CompanionManager) {
        overlayViewModel.companion = companion
    }

    func showOverlayAndBeginStreaming(clearText: Bool = true) {
        guard visibilityPolicy.canPresent else { return }

        if clearText {
            overlayViewModel.streamingResponseText = ""
        }
        overlayViewModel.isHovered = false
        overlayViewModel.isShowingResponse = true
        createOverlayPanelIfNeeded()
        startCursorTracking()
        isVisible = true
        #if DEBUG
        debugAnchorSamplesRemaining = 12
        #endif
        overlayPanel?.alphaValue = overlayViewModel.companion?.cursorOverlayState.aiPointerScreenLocation == nil ? 0 : 1
        repositionPanelNearCursor()
        overlayPanel?.orderFrontRegardless()
    }

    func updateStreamingText(_ accumulatedText: String) {
        guard visibilityPolicy.canPresent else { return }
        overlayViewModel.streamingResponseText = accumulatedText
        #if DEBUG
        debugAnchorSamplesRemaining = 12
        #endif
        resizePanelToFitContent()
        // Published SwiftUI text may lay out on the next main-loop pass.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isVisible else { return }
            self.resizePanelToFitContent()
        }
    }

    func dismissCurrentReply() {
        visibilityPolicy.dismiss()
        hideOverlay(resetReply: false)
    }

    func hideOverlay(resetReply: Bool = true) {
        if resetReply { visibilityPolicy.beginNewReply() }
        stopCursorTracking()
        overlayViewModel.isHovered = false
        overlayViewModel.isShowingResponse = false
        overlayViewModel.streamingResponseText = ""
        overlayPanel?.orderOut(nil)
        let wasVisible = isVisible
        isVisible = false
        if wasVisible {
            onHidden?()
        }
    }

    // MARK: - Private

    private func createOverlayPanelIfNeeded() {
        if overlayPanel != nil { return }

        let initialFrame = NSRect(x: 0, y: 0, width: overlayMaxWidth, height: 56)
        let responseOverlayPanel = NSPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        responseOverlayPanel.identifier = NSUserInterfaceItemIdentifier("tutor.reply")
        responseOverlayPanel.level = .statusBar
        responseOverlayPanel.isOpaque = false
        responseOverlayPanel.backgroundColor = .clear
        responseOverlayPanel.hasShadow = false
        // The dismiss button needs mouse events; the bubble freezes on hover.
        responseOverlayPanel.ignoresMouseEvents = false
        responseOverlayPanel.hidesOnDeactivate = false
        responseOverlayPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        responseOverlayPanel.isExcludedFromWindowsMenu = true

        let hostingView = NSHostingView(
            rootView: CompanionResponseOverlayView(viewModel: overlayViewModel)
                .frame(width: overlayMaxWidth)
                .fixedSize(horizontal: false, vertical: true)
        )
        responseHostingView = hostingView
        updateHostingWidth = { [weak hostingView, weak self] width in
            guard let self else { return }
            hostingView?.rootView = CompanionResponseOverlayView(viewModel: self.overlayViewModel)
                .frame(width: width)
                .fixedSize(horizontal: false, vertical: true)
        }
        hostingView.frame = NSRect(origin: .zero, size: initialFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        responseOverlayPanel.contentView = hostingView

        overlayPanel = responseOverlayPanel
    }

    private func startCursorTracking() {
        guard cursorTrackingTimer == nil else { return }
        lastCursorTrackingOrigin = nil

        // Keep the response bubble glued to the cursor during drags/menus, but
        // avoid queueing extra MainActor tasks every frame. The timer already
        // fires on the main run loop (`.common`), so the closure is already
        // main-thread / main-actor-isolated.
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.repositionPanelNearCursor()
            }
        }
        cursorTrackingTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopCursorTracking() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = nil
        lastCursorTrackingOrigin = nil
    }

    private func repositionPanelNearCursor() {
        guard let overlayPanel, !overlayViewModel.isHovered else { return }

        guard let pointerLocation = overlayViewModel.companion?.cursorOverlayState.aiPointerScreenLocation else { return }
        overlayPanel.alphaValue = 1
        let panelSize = overlayPanel.frame.size

        guard let screen = NSScreen.screen(containingOrNearestTo: pointerLocation) else { return }
        let nextOrigin = ReplyBubblePlacement.origin(anchor: pointerLocation, size: panelSize, visibleFrame: screen.visibleFrame)
        if let lastCursorTrackingOrigin,
           abs(lastCursorTrackingOrigin.x - nextOrigin.x) < 0.5,
           abs(lastCursorTrackingOrigin.y - nextOrigin.y) < 0.5 {
            return
        }
        lastCursorTrackingOrigin = nextOrigin
        overlayPanel.setFrameOrigin(nextOrigin)
        #if DEBUG
        let now = Date().timeIntervalSinceReferenceDate
        if debugAnchorSamplesRemaining > 0, now - debugLastAnchorSampleAt > 0.15 {
            debugAnchorSamplesRemaining -= 1
            debugLastAnchorSampleAt = now
            debugLogGeometry()
        }
        #endif
    }

    #if DEBUG
    func debugCapturePanel() {
        guard let panel = overlayPanel, isVisible else { return }
        Task { @MainActor in
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let window = content.windows.first(where: { $0.windowID == panel.windowNumber }) else { return }
                let config = SCStreamConfiguration()
                let scale = panel.backingScaleFactor
                config.width = Int(panel.frame.width * scale)
                config.height = Int(panel.frame.height * scale)
                config.showsCursor = false
                let cgImage = try await SCScreenshotManager.captureImage(contentFilter: SCContentFilter(desktopIndependentWindow: window), configuration: config)
                if let png = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) {
                    try png.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("OpenClicky-reply-panel.png"), options: .atomic)
                }
            } catch {
                print("Reply panel capture failed: \(error.localizedDescription)")
            }
        }
    }

    func debugLogGeometry() {
        guard let panel = overlayPanel, let content = panel.contentView else { return }
        // The existing hosting root has a frame modifier, so also record all children.
        OpenClickyMessageLogStore.shared.append(lane: "voice", direction: "internal", event: "response_panel.geometry", fields: [
            "windowWidth": panel.frame.width, "windowHeight": panel.frame.height,
            "wrapperWidth": content.fittingSize.width, "wrapperHeight": content.fittingSize.height,
            "childSizes": content.subviews.map { "\(type(of: $0)):\($0.fittingSize.width)x\($0.fittingSize.height)" }.joined(separator: ";"),
            "visible": isVisible, "textLength": overlayViewModel.streamingResponseText.count,
            "anchorX": overlayViewModel.companion?.cursorOverlayState.aiPointerScreenLocation?.x ?? -1,
            "anchorY": overlayViewModel.companion?.cursorOverlayState.aiPointerScreenLocation?.y ?? -1,
            "bubbleX": panel.frame.minX, "bubbleY": panel.frame.minY,
            "mouseX": NSEvent.mouseLocation.x, "mouseY": NSEvent.mouseLocation.y
        ])
    }
    #endif

    private func resizePanelToFitContent() {
        guard let overlayPanel, let contentView = overlayPanel.contentView,
              let responseHostingView else { return }

        // The glass wrapper reports 10x10, regardless of its SwiftUI child.
        // Measure the actual response host so text cannot become a clipped square.
        let textWidth = (overlayViewModel.streamingResponseText as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 13)]).width
        let desiredWidth = min(max(ceil(textWidth) + 44, 124), 340)
        updateHostingWidth?(desiredWidth)
        responseHostingView.layoutSubtreeIfNeeded()
        let fittingSize = responseHostingView.fittingSize
        let newWidth = desiredWidth
        let newHeight = max(ceil(fittingSize.height), 34)

        // Keep the panel origin relative to the cursor (the timer handles that),
        // but update the frame size so the content fits.
        var frame = overlayPanel.frame
        let heightDelta = newHeight - frame.height
        frame.size = CGSize(width: newWidth, height: newHeight)
        // Adjust origin Y so the panel grows upward (toward the cursor), not downward
        frame.origin.y -= heightDelta
        overlayPanel.setFrame(frame, display: true)
        contentView.frame = NSRect(origin: .zero, size: frame.size)
        repositionPanelNearCursor()
        #if DEBUG
        debugLogGeometry()
        #endif
    }


}

// MARK: - SwiftUI View

private struct CompanionResponseOverlayView: View {
    @ObservedObject var viewModel: CompanionResponseOverlayViewModel

    var body: some View {
        if viewModel.isShowingResponse {
            HStack(alignment: .top, spacing: 8) {
                FormattedReplyText(text: viewModel.streamingResponseText.isEmpty ? "..." : viewModel.streamingResponseText)
                    .frame(maxWidth: 320, alignment: .leading)
                Button {
                    viewModel.companion?.dismissCoachingOverlays()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Dismiss coaching reply")
                .help("Dismiss reply and highlights (Esc)")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .onHover { hovered in
                DispatchQueue.main.async {
                    viewModel.isHovered = hovered && viewModel.isShowingResponse
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DS.Colors.surface1.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Colors.borderSubtle.opacity(0.5), lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
            )
        }
    }
}

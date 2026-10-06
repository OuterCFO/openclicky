import Foundation

nonisolated enum OpenClickyPresentationPolicy {
    static var menuBarOnly: Bool {
        UserDefaults.standard.object(forKey: "openclicky.menuBarOnlyPresentation") as? Bool ?? true
    }
}

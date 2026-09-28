import SwiftUI

struct AgendaPalette {
    let scheme: ColorScheme
    var surface: Color {
        scheme == .dark ? Color(red: 0.12, green: 0.13, blue: 0.14) : Color(red: 0.985, green: 0.98, blue: 0.97)
    }

    var footer: Color {
        scheme == .dark ? Color(red: 27 / 255, green: 39 / 255, blue: 59 / 255) : Color(red: 237 / 255, green: 242 / 255, blue: 250 / 255)
    }

    var accent: Color {
        scheme == .dark ? Color(red: 142 / 255, green: 181 / 255, blue: 241 / 255) : Self.button
    }

    static let button = Color(red: 36 / 255, green: 87 / 255, blue: 166 / 255)
    static let sun = Color(red: 0.96, green: 0.65, blue: 0.05)
    static let moon = Color(red: 0.34, green: 0.38, blue: 0.58)
}

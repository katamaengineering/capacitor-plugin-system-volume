import XCTest
import UIKit
@testable import CapacitorSystemVolumePlugin

class CapacitorSystemVolumePluginTests: XCTestCase {

    // MARK: - Hex colour parsing

    func testParsesSixDigitHex() {
        let color = UIColor(cssHex: "#B4FF39")
        XCTAssertNotNil(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0xB4 / 255.0, accuracy: 0.001)
        XCTAssertEqual(g, 0xFF / 255.0, accuracy: 0.001)
        XCTAssertEqual(b, 0x39 / 255.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func testParsesShorthandHex() {
        // "#0f0" expands to "#00ff00"
        let color = UIColor(cssHex: "0f0")
        XCTAssertNotNil(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0, accuracy: 0.001)
        XCTAssertEqual(g, 1, accuracy: 0.001)
        XCTAssertEqual(b, 0, accuracy: 0.001)
    }

    func testParsesEightDigitHexAlpha() {
        let color = UIColor(cssHex: "#00000080")
        var a: CGFloat = 0
        color?.getRed(nil, green: nil, blue: nil, alpha: &a)
        XCTAssertEqual(a, 0x80 / 255.0, accuracy: 0.01)
    }

    func testRejectsGarbage() {
        XCTAssertNil(UIColor(cssHex: "not-a-color"))
        XCTAssertNil(UIColor(cssHex: "#12"))
    }

    // MARK: - Style image generation

    func testTrackAndThumbImagesAreNonEmpty() {
        let color = UIColor(cssHex: "#B4FF39")!
        XCTAssertGreaterThan(color.trackImage().size.width, 0)
        let thumb = color.thumbImage(radius: 16)
        XCTAssertEqual(thumb.size.width, 16, accuracy: 0.5)
        XCTAssertEqual(thumb.size.height, 16, accuracy: 0.5)
    }
}

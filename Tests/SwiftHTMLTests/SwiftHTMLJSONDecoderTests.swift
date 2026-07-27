import Foundation
@testable import SwiftHTML
import Testing

private class JSONDecoderBaseFixture: Codable {
    let baseValue: Int

    init(baseValue: Int) {
        self.baseValue = baseValue
    }
}

private final class JSONDecoderDerivedFixture: JSONDecoderBaseFixture {
    let derivedValue: String

    private enum CodingKeys: String, CodingKey {
        case derivedValue
    }

    init(baseValue: Int, derivedValue: String) {
        self.derivedValue = derivedValue
        super.init(baseValue: baseValue)
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.derivedValue = try container.decode(String.self, forKey: .derivedValue)
        try super.init(from: container.superDecoder())
    }

    override func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(derivedValue, forKey: .derivedValue)
        try super.encode(to: container.superEncoder())
    }
}

@Suite
struct SwiftHTMLJSONDecoderTests {
    @Test
    func decodesJSONEncoderBase64Data() throws {
        let expected = Data([0, 1, 2, 127, 255])
        let encoded = try JSONEncoder().encode(expected)

        let decoded = try SwiftHTMLJSONDecoder.decode(Data.self, from: encoded)

        #expect(decoded == expected)
    }

    @Test
    func decodesInheritedCodableSuperPayload() throws {
        let expected = JSONDecoderDerivedFixture(baseValue: 42, derivedValue: "child")
        let encoded = try JSONEncoder().encode(expected)

        let decoded = try SwiftHTMLJSONDecoder.decode(
            JSONDecoderDerivedFixture.self,
            from: encoded
        )

        #expect(decoded.baseValue == 42)
        #expect(decoded.derivedValue == "child")
    }
}

import Foundation

public struct StateSchema: Sendable, Codable, Equatable {
    public let hash: String
    public let slots: [StateSlotRecord]

    public init(slots: [StateSlotRecord]) {
        self.slots = slots.sorted { left, right in
            left.id.rawValue < right.id.rawValue
        }
        self.hash = Self.hash(self.slots)
    }

    public static func hash(_ slots: [StateSlotRecord]) -> String {
        stableHash(slots.sorted { left, right in
            left.id.rawValue < right.id.rawValue
        }
        .map { slot in
            "\(slot.id.rawValue)|\(slot.valueType)|\(slot.source.rawValue)"
        }
        .joined(separator: "\n"))
    }

    private static func stableHash(_ value: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return String(format: "%016llx", hash)
    }
}

public extension HydrationManifest {
    var stateSchema: StateSchema {
        StateSchema(slots: components.flatMap(\.stateSlots))
    }

    var stateSchemaHash: String {
        stateSchema.hash
    }
}

public extension HydrationComponentRecord {
    var stateSchema: StateSchema {
        StateSchema(slots: stateSlots)
    }

    var stateSchemaHash: String {
        stateSchema.hash
    }
}

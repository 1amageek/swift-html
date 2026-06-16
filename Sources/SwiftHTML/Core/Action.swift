public struct Action: ActionRepresentable, Sendable, Equatable, Codable {
    public let path: String
    public let method: FormMethod
    public let fields: [ActionField]

    public init(
        path: String,
        method: FormMethod = .post,
        fields: [ActionField] = []
    ) {
        self.path = path
        self.method = method
        self.fields = fields
    }

    public static func post(
        _ path: String,
        fields: [ActionField] = []
    ) -> Action {
        Action(path: path, method: .post, fields: fields)
    }

    public static func post(
        _ path: String,
        name: String,
        value: String
    ) -> Action {
        .post(path, fields: [ActionField(name, value)])
    }

    public static func post(
        _ path: String,
        name: String,
        value: Int
    ) -> Action {
        .post(path, fields: [ActionField(name, value)])
    }

    public static func post(
        _ path: String,
        name: String,
        value: Bool
    ) -> Action {
        .post(path, fields: [ActionField(name, value)])
    }

    public static func get(
        _ path: String,
        fields: [ActionField] = []
    ) -> Action {
        Action(path: path, method: .get, fields: fields)
    }
}

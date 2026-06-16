public protocol ActionRepresentable: Sendable {
    var path: String { get }
    var method: FormMethod { get }
    var fields: [ActionField] { get }
}

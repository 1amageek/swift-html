public struct ActionHiddenFieldsEnvironmentKey: EnvironmentKey {
    public static let defaultValue: [ActionField] = []

    public init() {}
}

public extension EnvironmentValues {
    var actionHiddenFields: [ActionField] {
        get { self[ActionHiddenFieldsEnvironmentKey.self] }
        set { self[ActionHiddenFieldsEnvironmentKey.self] = newValue }
    }
}

private struct ActionHiddenFieldsEnvironmentKey: EnvironmentKey {
    static let defaultValue: [ActionField] = []
}

public extension EnvironmentValues {
    var actionHiddenFields: [ActionField] {
        get { self[ActionHiddenFieldsEnvironmentKey.self] }
        set { self[ActionHiddenFieldsEnvironmentKey.self] = newValue }
    }
}

import Foundation

/// A CSS easing function — the timing half of a transition or animation.
///
/// Standard cases lower to the matching CSS keyword/`cubic-bezier(...)`. `spring`
/// has no native CSS form, so it is approximated by sampling the step response of
/// a damped harmonic oscillator into a `linear()` easing. The approximation is
/// deliberate (a browser cannot run SwiftUI's spring solver); it is not silently
/// substituted for an exact spring.
public struct TimingFunction: Sendable, Equatable {
    public let cssValue: String

    init(cssValue: String) {
        self.cssValue = cssValue
    }

    public static let linear = TimingFunction(cssValue: "linear")
    public static let ease = TimingFunction(cssValue: "ease")
    public static let easeIn = TimingFunction(cssValue: "cubic-bezier(0.42, 0, 1, 1)")
    public static let easeOut = TimingFunction(cssValue: "cubic-bezier(0, 0, 0.58, 1)")
    public static let easeInOut = TimingFunction(cssValue: "cubic-bezier(0.42, 0, 0.58, 1)")

    public static func cubicBezier(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> TimingFunction {
        TimingFunction(cssValue: "cubic-bezier(\(trimmed(x1)), \(trimmed(y1)), \(trimmed(x2)), \(trimmed(y2)))")
    }

    public static func steps(_ count: Int, _ position: StepPosition = .end) -> TimingFunction {
        TimingFunction(cssValue: "steps(\(count), \(position.rawValue))")
    }

    public enum StepPosition: String, Sendable, Equatable {
        case start = "jump-start"
        case end = "jump-end"
    }

    /// Approximates a spring as a `linear()` easing by sampling the unit step
    /// response of a second-order system. `bounce` maps to the damping ratio:
    /// `0` is critically damped (no overshoot), `> 0` underdamped (overshoots),
    /// `< 0` overdamped (slow, no overshoot). The easing is normalized over its
    /// timeline, so duration is not a curve parameter — the caller sets it as the
    /// transition/animation duration.
    public static func spring(bounce: Double = 0.0) -> TimingFunction {
        let zeta: Double = bounce >= 0 ? max(1.0 - bounce, 0.0001) : 1.0 / (1.0 + max(bounce, -0.999))
        let omega = 6.0
        let sampleCount = 24
        var stops: [String] = []
        for index in 0...sampleCount {
            let t = Double(index) / Double(sampleCount)
            let position: Double
            if index == 0 {
                position = 0
            } else if index == sampleCount {
                position = 1
            } else {
                position = springPosition(t: t, zeta: zeta, omega: omega)
            }
            let percent = Int((t * 100).rounded())
            stops.append("\(trimmed(position)) \(percent)%")
        }
        return TimingFunction(cssValue: "linear(\(stops.joined(separator: ", ")))")
    }

    private static func springPosition(t: Double, zeta: Double, omega: Double) -> Double {
        if zeta < 1 {
            let damped = omega * (1 - zeta * zeta).squareRoot()
            let envelope = exp(-zeta * omega * t)
            return 1 - envelope * (cos(damped * t) + (zeta / (1 - zeta * zeta).squareRoot()) * sin(damped * t))
        } else if zeta == 1 {
            return 1 - exp(-omega * t) * (1 + omega * t)
        } else {
            let spread = (zeta * zeta - 1).squareRoot()
            let root1 = -omega * (zeta - spread)
            let root2 = -omega * (zeta + spread)
            let a = root2 / (root2 - root1)
            let b = -root1 / (root2 - root1)
            return 1 - (a * exp(root1 * t) + b * exp(root2 * t))
        }
    }

    private static func trimmed(_ value: Double) -> String {
        let rounded = (value * 1000).rounded() / 1000
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}

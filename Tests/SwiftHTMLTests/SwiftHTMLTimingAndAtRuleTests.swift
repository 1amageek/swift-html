import SwiftHTML
import Testing

@Suite
struct SwiftHTMLTimingAndAtRuleTests {
    @Test
    func standardTimingFunctionsLowerToCSS() {
        #expect(TimingFunction.linear.cssValue == "linear")
        #expect(TimingFunction.ease.cssValue == "ease")
        #expect(TimingFunction.easeInOut.cssValue == "cubic-bezier(0.42, 0, 0.58, 1)")
        #expect(TimingFunction.cubicBezier(0.2, 0, 0, 1).cssValue == "cubic-bezier(0.2, 0, 0, 1)")
    }

    @Test
    func springApproximatesToLinearEasing() {
        let spring = TimingFunction.spring(bounce: 0.3).cssValue
        #expect(spring.hasPrefix("linear("))
        // A bouncy spring overshoots past 1 before settling, which `linear()` can
        // express with stops greater than 1.
        #expect(spring.contains("100%"))
        // Endpoints are pinned so the easing runs cleanly from 0 to 1.
        #expect(spring.contains("0 0%"))
        #expect(spring.contains("1 100%"))
    }

    @Test
    func keyframesRenderTyped() {
        let item = keyframes("spin") {
            Keyframe("to") { .transform("rotate(360deg)") }
        }
        #expect(item.cssText.contains("@keyframes spin {"))
        #expect(item.cssText.contains("to {"))
        #expect(item.cssText.contains("transform: rotate(360deg);"))
    }

    @Test
    func mediaAndSupportsNestTypedRules() {
        let sheet = Stylesheet {
            rule(".a") { .color("red") }
            media("(max-width: 600px)") {
                rule(".a") { .color("blue") }
            }
            supports("(display: grid)") {
                rule(".grid") { .display("grid") }
            }
        }
        let css = sheet.cssText
        #expect(css.contains(".a {"))
        #expect(css.contains("@media (max-width: 600px) {"))
        #expect(css.contains("@supports (display: grid) {"))
        // The flat rules accessor excludes at-rules.
        #expect(sheet.rules.count == 1)
        #expect(sheet.items.count == 3)
    }

    @Test
    func startingStyleRendersTyped() {
        let item = startingStyle {
            rule(".dialog") { .opacity("0") }
        }
        #expect(item.cssText.contains("@starting-style {"))
        #expect(item.cssText.contains(".dialog {"))
    }
}

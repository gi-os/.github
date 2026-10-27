import Testing
@testable import __APP__

struct GreetingTests {
    @Test func greetsByName() {
        #expect(Greeting.text(for: "Basil") == "Hello from Basil")
    }
}

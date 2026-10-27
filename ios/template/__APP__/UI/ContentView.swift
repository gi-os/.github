import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.tint)
            Text(Greeting.text(for: "__DISPLAY__"))
                .font(.title2.bold())
        }
        .padding()
    }
}

/// Logic lives outside the views so the unit tests can reach it.
enum Greeting {
    static func text(for name: String) -> String {
        "Hello from \(name)"
    }
}

#Preview {
    ContentView()
}

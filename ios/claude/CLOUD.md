
**This is a Linux cloud session: no Xcode, no simulator.** `xcodebuild`, `xcodegen` and `swift` for
UIKit/SwiftUI code don't exist here. To verify a change: commit, push the branch, and let **Check** compile
and test it on macOS, then read the result with the GitHub MCP tools (see the `gios-fix-ci` skill). Before
pushing, re-read the diff the way the compiler will: every new symbol defined, imports present, types match,
`@MainActor` / `Sendable` where the surrounding code uses them. One careful push beats three speculative ones.

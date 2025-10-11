# AwesomeUserNotifications

## Development

Open `AwesomeUserNotifications.xcworkspace` at the repository root, select the
`AwesomeUserNotifications` scheme and an iOS simulator, then press ⌘B to build
the library or ⌘U to run all tests. The scheme's default `AllTests` plan includes
both the unit tests and the app-hosted integration tests. `Package.swift` defines
only the library.

The workspace, shared scheme, test plan, and test project belong in
version control. Xcode's per-user settings and generated package workspace remain
ignored.

Use the workspace rather than opening `Package.swift` directly so the integration
test app is available. The workspace disables automatic scheme creation and
provides one shared scheme for building and testing the package.

Test files and configuration live under `Tests`:

- `UnitTests`: unhosted unit tests, organized to mirror `Sources`.
- `IntegrationTests`: app-hosted integration tests.
- `Support`: fixtures shared by both test bundles.
- `TestApp`: the minimal app required to run the integration tests.
- `Tests.xcodeproj`: both test targets and the test app.
- `AllTests.xctestplan`: the default plan that runs both test bundles.

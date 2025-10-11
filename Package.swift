// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "AwesomeUserNotifications",
	platforms: [
		.iOS(.v16)
	],
	products: [
		.library(
			name: "AwesomeUserNotifications",
			targets: ["AwesomeUserNotifications"],
		),
	],
	targets: [
		.target(
			name: "AwesomeUserNotifications",
			swiftSettings: [
				.defaultIsolation(MainActor.self),
				.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
			],
		),
	]
)

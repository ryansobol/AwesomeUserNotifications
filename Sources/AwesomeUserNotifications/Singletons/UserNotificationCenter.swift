import UIKit
import UserNotifications

public enum UserNotificationCenter {
	// MARK: Adapter

	private static let adapter = {
		let adapter = Adapter()

		UNUserNotificationCenter.current().delegate = adapter

		return adapter
	}()

	// MARK: AsyncStreams

	internal static var alertNotificationsStream: AsyncStream<AlertNotification> {
		return self.adapter.alertNotificationsTopic.subscribe()
	}

	internal static var alertNotificationResponsesStream: AsyncStream<AlertNotificationResponse> {
		return self.adapter.alertNotificationResponsesTopic.subscribe()
	}

	internal static var backgroundNotificationsStream: AsyncStream<BackgroundNotification> {
		return self.adapter.backgroundNotificationsTopic.subscribe()
	}

	internal static var deviceTokenResultsStream: AsyncStream<Result<Data, Swift.Error>> {
		return self.adapter.deviceTokenResultsTopic.subscribe()
	}

	// TODO: Consider whether wraping this stream in a view modifier would be valuable
	internal static var authorizationStatusStream: AsyncStream<UNAuthorizationStatus> {
		return self.makeAuthorizationStatusStream(
			activations: NotificationCenter.default.notifications(
				named: UIApplication.didBecomeActiveNotification
			),
			readAuthorizationStatus: {
				let settings = await self.notificationSettings

				return settings.authorizationStatus
			}
		)
	}

	/// Creates a stream that reads authorization status immediately and again after each activation.
	///
	/// Kept separate from `authorizationStatusStream` so tests can drive activations
	/// through a private `NotificationCenter` and supply known statuses. This allows
	/// sequencing and cancellation to be tested without application-wide notifications
	/// or reading system notification settings.
	///
	/// - Parameter activations: Notifications that trigger a fresh status read.
	/// - Parameter readAuthorizationStatus: Reads the status initially and after each activation.
	internal static func makeAuthorizationStatusStream(
		activations: NotificationCenter.Notifications,
		readAuthorizationStatus: @escaping @MainActor () async -> UNAuthorizationStatus
	) -> AsyncStream<UNAuthorizationStatus> {
		return AsyncStream { continuation in
			let task = Task {
				// Finish the stream when this task exits, including early returns after cancellation.
				defer { continuation.finish() }

				guard !Task.isCancelled else { return }

				// Publish the current status first, without waiting for an activation.
				let initialStatus = await readAuthorizationStatus()

				continuation.yield(initialStatus)

				// Wait for the app to become active before each subsequent status check.
				for await _ in activations {
					guard !Task.isCancelled else { return }

					// Read the current status to pick up permission changes made in Settings.
					let updatedStatus = await readAuthorizationStatus()

					// Publish a status for every activation, even if it matches the previous value.
					continuation.yield(updatedStatus)
				}
			}

			// When the stream terminates, ask its producer task to stop as well.
			continuation.onTermination = { _ in
				task.cancel()
			}
		}
	}

	// MARK: Computed Properties

	// TODO: Consider whether all of these public APIs should exist in v1.0.0

	public static var notificationSettings: UNNotificationSettings {
		get async {
			return await UNUserNotificationCenter.current().notificationSettings()
		}
	}

	public static var pendingLocalNotificationRequests: [UNNotificationRequest] {
		get async {
			return await UNUserNotificationCenter.current().pendingNotificationRequests()
		}
	}

	public static var deliveredAlertNotifications: [UNNotification] {
		get async {
			return await UNUserNotificationCenter.current().deliveredNotifications()
		}
	}

	public static var notificationCategories: Set<UNNotificationCategory> {
		get async {
			return await UNUserNotificationCenter.current().notificationCategories()
		}
	}

	public static func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
		return UNUserNotificationCenter.current().setNotificationCategories(categories)
	}

	// MARK: Methods

	// TODO: Consider whether all of these public APIs should exist in v1.0.0

	internal static func requestAuthorization(
		with options: UNAuthorizationOptions
	) async throws -> Bool {
		return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
	}

	internal static func registerForRemoteNotifications() -> Void {
		UIApplication.shared.registerForRemoteNotifications()
	}

	public static func scheduleLocalNotification(
		_ request: UNNotificationRequest
	) async throws -> Void {
		return try await UNUserNotificationCenter.current().add(request)
	}

	public static func removePendingLocalNotificationRequests(
		withIdentifiers identifiers: [String]
	) -> Void {
		return UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
	}

	public static func removeDeliveredAlertNotifications(
		withIdentifiers identifiers: [String]
	) -> Void {
		return UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
	}
}

// MARK: - UIAppDelegate Integration

extension UserNotificationCenter {
	// MARK: BackgroundNotification

	public static func didReceiveBackgroundNotification(
		userInfo: [AnyHashable: Any],
		completionHandler: @escaping (UIBackgroundFetchResult) -> Void
	) {
		self.adapter.didReceiveBackgroundNotification(
			userInfo: userInfo,
			completionHandler: completionHandler
		)
	}

	// MARK: Device token

	public static func didRegister(with deviceToken: Data) -> Void {
		self.adapter.didRegisterForRemoteNotifications(deviceToken: deviceToken)
	}

	public static func didFailToRegister(with error: any Swift.Error) -> Void {
		self.adapter.didFailToRegisterForRemoteNotifications(error: error)
	}
}

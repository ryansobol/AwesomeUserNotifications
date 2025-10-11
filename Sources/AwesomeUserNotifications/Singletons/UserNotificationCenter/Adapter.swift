import Foundation
import UIKit
import UserNotifications

extension UserNotificationCenter {
	// MARK: - NSObject

	internal final class Adapter: NSObject {
		// MARK: AsyncTopics

		let alertNotificationsTopic = AsyncTopic<AlertNotification>()
		let alertNotificationResponsesTopic = AsyncTopic<AlertNotificationResponse>()
		let backgroundNotificationsTopic = AsyncTopic<BackgroundNotification>()
		let deviceTokenResultsTopic = AsyncTopic<Result<Data, Swift.Error>>()
	}
}

// MARK: - UNUserNotificationCenterDelegate

/// Delegate methods are called from the main thread, so they must run on the MainActor under Swift
/// Concurrency
///
/// See:
///   - https://developer.apple.com/forums/thread/735651
///   - https://stackoverflow.com/a/74399999
extension UserNotificationCenter.Adapter: UNUserNotificationCenterDelegate {
	// MARK: AlertNotification

	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		willPresent notification: UNNotification,
		withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
	) -> Void {
		self.willPresentAlertNotification(
			notification: notification,
			completionHandler: completionHandler
		)
	}

	/// Publishes a foreground alert with the supplied presentation handler.
	///
	/// The delegate callback forwards here so tests can exercise publication and
	/// handler forwarding without its unused `UNUserNotificationCenter` argument.
	/// The center has no public initializer, and calling `current()` aborts the
	/// package's unhosted test runner.
	func willPresentAlertNotification(
		notification: UNNotification,
		completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
	) -> Void {
		let alertNotification = AlertNotification(
			notification: notification,
			presentationHandler: completionHandler
		)

		self.alertNotificationsTopic.publish(alertNotification)
	}

	// MARK: AlertNotificationResponse

	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		didReceive response: UNNotificationResponse,
		withCompletionHandler completionHandler: @escaping () -> Void
	) -> Void {
		self.didReceiveAlertNotificationResponse(
			response: response,
			completionHandler: completionHandler
		)
	}

	/// Publishes a notification response with the supplied completion handler.
	///
	/// The delegate callback forwards here so tests can exercise publication and
	/// handler forwarding without its unused `UNUserNotificationCenter` argument.
	/// The center has no public initializer, and calling `current()` aborts the
	/// package's unhosted test runner.
	func didReceiveAlertNotificationResponse(
		response: UNNotificationResponse,
		completionHandler: @escaping () -> Void
	) -> Void {
		let alertNotificationResponse = AlertNotificationResponse(
			response: response,
			completionHandler: completionHandler
		)

		self.alertNotificationResponsesTopic.publish(alertNotificationResponse)
	}
}

// MARK: - UIAppDelegate Integration

extension UserNotificationCenter.Adapter {
	// MARK: BackgroundNotification

	func didReceiveBackgroundNotification(
		userInfo: [AnyHashable: Any],
		completionHandler: @escaping (UIBackgroundFetchResult) -> Void
	) -> Void {
		let notification = BackgroundNotification(
			userInfo: userInfo,
			completionHandler: completionHandler
		)

		self.backgroundNotificationsTopic.publish(notification)
	}

	// MARK: Device token

	func didRegisterForRemoteNotifications(deviceToken: Data) -> Void {
		self.deviceTokenResultsTopic.publish(.success(deviceToken))
	}

	func didFailToRegisterForRemoteNotifications(error: any Swift.Error) -> Void {
		self.deviceTokenResultsTopic.publish(.failure(error))
	}
}

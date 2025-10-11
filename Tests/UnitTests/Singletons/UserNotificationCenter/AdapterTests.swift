import Foundation
import Testing
import UIKit
import UserNotifications
@testable import AwesomeUserNotifications

@MainActor
@Suite("UserNotificationCenter.Adapter", .timeLimit(.minutes(1)))
struct AdapterTests {

	/// Creates an adapter scoped to synchronous test setup.
	///
	/// Returned streams finish after `action` returns, provided `action`
	/// does not retain the adapter or its topics.
	private func withAdapter<T>(
		_ action: (UserNotificationCenter.Adapter) -> T
	) -> T {
		return action(UserNotificationCenter.Adapter())
	}

	@Test("Foreground alerts publish the original notification and preserve the supplied presentation handler")
	func alertNotificationDelivery() async throws -> Void {
		let notification = try #require(try UNNotification())
		let options: UNNotificationPresentationOptions = [.banner, .sound]

		var capturedPresentationOptions: [UNNotificationPresentationOptions] = []

		let stream = withAdapter { adapter in
			let stream = adapter.alertNotificationsTopic.subscribe()

			adapter.willPresentAlertNotification(notification: notification) {
				capturedPresentationOptions.append($0)
			}

			return stream
		}

		let notifications = await Array(stream)

		try #require(notifications.count == 1)

		#expect(notifications[0].notification === notification)
		#expect(capturedPresentationOptions.isEmpty)

		notifications[0].present(with: options)

		#expect(capturedPresentationOptions == [options])
	}

	@Test("Notification responses publish the original response and preserve the supplied completion handler")
	func alertNotificationResponseDelivery() async throws -> Void {
		let response = try #require(try UNNotificationResponse())

		var completionCount = 0

		let stream = withAdapter { adapter in
			let stream = adapter.alertNotificationResponsesTopic.subscribe()

			adapter.didReceiveAlertNotificationResponse(response: response) {
				completionCount += 1
			}

			return stream
		}

		let responses = await Array(stream)

		try #require(responses.count == 1)

		#expect(responses[0].notificationResponse === response)
		#expect(completionCount == 0)

		responses[0].complete()

		#expect(completionCount == 1)
	}

	@Test("Background callbacks publish the payload and preserve the supplied completion handler")
	func backgroundNotificationDelivery() async throws -> Void {
		let userInfo = ["post_id": "42"]

		var capturedFetchResults: [UIBackgroundFetchResult] = []

		let stream = withAdapter { adapter in
			let stream = adapter.backgroundNotificationsTopic.subscribe()

			adapter.didReceiveBackgroundNotification(userInfo: userInfo) {
				capturedFetchResults.append($0)
			}

			return stream
		}

		let notifications = await Array(stream)

		try #require(notifications.count == 1)

		#expect(notifications[0].userInfo as? [String: String] == userInfo)
		#expect(capturedFetchResults.isEmpty)

		notifications[0].complete(with: .newData)

		#expect(capturedFetchResults == [.newData])
	}

	@Test("Initial device tokens and subsequent updates are published in callback order")
	func initialTokenAndSubsequentUpdatesAreDeliveredInOrder() async throws -> Void {
		let tokens = [Data([1]), Data([2]), Data([3])]

		let stream = withAdapter { adapter in
			let stream = adapter.deviceTokenResultsTopic.subscribe()

			for token in tokens {
				adapter.didRegisterForRemoteNotifications(deviceToken: token)
			}

			return stream
		}

		let results = await Array(stream)

		#expect(try results.map { try $0.get() } == tokens)
	}

	@Test("Registration failures are published without interrupting device-token delivery")
	func registrationFailuresDoNotInterruptTokenDelivery() async throws -> Void {
		let initialToken = Data([1])
		let updatedToken = Data([2])

		let stream = withAdapter { adapter in
			let stream = adapter.deviceTokenResultsTopic.subscribe()

			adapter.didFailToRegisterForRemoteNotifications(error: RegistrationFailure.unavailable)
			adapter.didRegisterForRemoteNotifications(deviceToken: initialToken)
			adapter.didFailToRegisterForRemoteNotifications(error: RegistrationFailure.unavailable)
			adapter.didRegisterForRemoteNotifications(deviceToken: updatedToken)

			return stream
		}

		let results = await Array(stream)

		try #require(results.count == 4)

		#expect(throws: RegistrationFailure.unavailable) { try results[0].get() }
		#expect(try results[1].get() == initialToken)
		#expect(throws: RegistrationFailure.unavailable) { try results[2].get() }
		#expect(try results[3].get() == updatedToken)
	}

	private enum RegistrationFailure: Error {
		case unavailable
	}
}

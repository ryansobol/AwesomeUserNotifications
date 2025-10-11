import Foundation
import Testing
import UIKit
import UserNotifications
@testable import AwesomeUserNotifications

// Serialize access to the application's shared UNUserNotificationCenter and delegate.
@MainActor
@Suite("UserNotificationCenter integration", .serialized, .timeLimit(.minutes(1)))
struct UserNotificationCenterIntegrationTests {

	@Test("The authorization stream initially publishes the application's current notification permission")
	func initialAuthorizationStatus() async throws -> Void {
		let settings = await UNUserNotificationCenter.current().notificationSettings()
		let stream = UserNotificationCenter.authorizationStatusStream
		var iterator = stream.makeAsyncIterator()

		#expect(await iterator.next() == settings.authorizationStatus)
	}

	@Test("The installed delegate delivers foreground alerts to the center's alert stream")
	func alertNotificationDelivery() async throws -> Void {
		let stream = UserNotificationCenter.alertNotificationsStream
		let center = UNUserNotificationCenter.current()
		let willPresent = try #require(
			center.delegate?.userNotificationCenter(_:willPresent:withCompletionHandler:)
		)
		let notification = try #require(try UNNotification())
		let options: UNNotificationPresentationOptions = [.banner, .sound]

		try await confirmation("The presentation handler receives the requested options") { presented in
			willPresent(center, notification) { actualOptions in
				#expect(actualOptions == options)
				presented()
			}

			var iterator = stream.makeAsyncIterator()
			let alert = try #require(await iterator.next())

			#expect(alert.notification === notification)

			alert.present(with: options)
		}
	}

	@Test("The installed delegate delivers responses to the center's response stream")
	func alertNotificationResponseDelivery() async throws -> Void {
		let stream = UserNotificationCenter.alertNotificationResponsesStream
		let center = UNUserNotificationCenter.current()
		let didReceive = try #require(
			center.delegate?.userNotificationCenter(_:didReceive:withCompletionHandler:)
		)
		let response = try #require(try UNNotificationResponse())

		try await confirmation("The response completion handler is invoked") { completed in
			didReceive(center, response) {
				completed()
			}

			var iterator = stream.makeAsyncIterator()
			let receivedResponse = try #require(await iterator.next())

			#expect(receivedResponse.notificationResponse === response)

			receivedResponse.complete()
		}
	}

	@Test("The public background callback delivers its payload and completion handler to the background stream")
	func backgroundNotificationDelivery() async throws -> Void {
		let stream = UserNotificationCenter.backgroundNotificationsStream
		let userInfo = ["post_id": "42"]

		try await confirmation("The background completion handler receives the fetch result") { completed in
			UserNotificationCenter.didReceiveBackgroundNotification(userInfo: userInfo) { result in
				#expect(result == .newData)
				completed()
			}

			var iterator = stream.makeAsyncIterator()
			let notification = try #require(await iterator.next())

			#expect(notification.userInfo as? [String: String] == userInfo)

			notification.complete(with: .newData)
		}
	}

	@Test("The public registration callbacks deliver success and failure to the device-token stream")
	func remoteNotificationRegistration() async throws -> Void {
		let stream = UserNotificationCenter.deviceTokenResultsStream
		let token = Data([1])

		UserNotificationCenter.didRegister(with: token)
		UserNotificationCenter.didFailToRegister(with: RegistrationFailure.unavailable)

		var iterator = stream.makeAsyncIterator()
		let success = try #require(await iterator.next())
		let failure = try #require(await iterator.next())

		#expect(try success.get() == token)
		#expect(throws: RegistrationFailure.unavailable) { try failure.get() }
	}

	private enum RegistrationFailure: Error {
		case unavailable
	}
}

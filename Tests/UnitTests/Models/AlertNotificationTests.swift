import Testing
import UserNotifications
@testable import AwesomeUserNotifications

@MainActor
@Suite("AlertNotification")
struct AlertNotificationTests {

	@Test("The alert exposes the original notification and its payload")
	func notificationPayload() throws -> Void {
		let userInfo = ["post_id": "42"]

		let content = UNMutableNotificationContent(userInfo: userInfo)

		let request = UNNotificationRequest(
			identifier: "post-42",
			content: content,
			trigger: nil
		)

		let notification = try #require(try UNNotification(request: request))

		let alert = AlertNotification(notification: notification, presentationHandler: { _ in })

		#expect(alert.notification === notification)
		#expect(alert.request == request)
		#expect(alert.content == content)
		#expect(alert.userInfo as? [String: String] == userInfo)
	}

	@Test(
		"Alerts distinguish remote notifications from immediate and scheduled local notifications",
		arguments: UNNotificationRequest.Delivery.allCases
	)
	func notificationOrigin(delivery: UNNotificationRequest.Delivery) throws -> Void {
		let request = try #require(try UNNotificationRequest(delivery: delivery))

		let notification = try #require(try UNNotification(request: request))

		let alert = AlertNotification(notification: notification, presentationHandler: { _ in })

		#expect(alert.isRemote == (delivery == .remote))
		#expect(alert.isLocal == (delivery != .remote))
	}

	@Test(
		"Presenting an alert invokes the supplied handler with the requested options",
		arguments: [
			UNNotificationPresentationOptions(),
			[.banner, .sound],
			[.banner, .list, .sound, .badge],
		]
	)
	func presentationInvoking(options: UNNotificationPresentationOptions) throws -> Void {
		let notification = try #require(try UNNotification())

		var receivedOptions: [UNNotificationPresentationOptions] = []

		let alert = AlertNotification(notification: notification) {
			receivedOptions.append($0)
		}

		#expect(receivedOptions.isEmpty)

		alert.present(with: options)

		#expect(receivedOptions == [options])
	}
}

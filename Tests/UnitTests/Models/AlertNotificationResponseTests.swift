import Foundation
import Testing
import UserNotifications
@testable import AwesomeUserNotifications

@MainActor
@Suite("AlertNotificationResponse")
struct AlertNotificationResponseTests {

	@Test("The response exposes the original notification and its payload")
	func notificationPayload() throws -> Void {
		let userInfo = ["post_id": "42"]

		let content = UNMutableNotificationContent(userInfo: userInfo)

		let request = UNNotificationRequest(
			identifier: "post-42",
			content: content,
			trigger: nil
		)

		let response = try #require(try UNNotificationResponse(request: request))

		let notification = AlertNotificationResponse(response: response, completionHandler: {})

		#expect(notification.notificationResponse === response)
		#expect(notification.notification == response.notification)
		#expect(notification.request == request)
		#expect(notification.content == content)
		#expect(notification.userInfo as? [String: String] == userInfo)
	}

	@Test(
		"Responses distinguish remote notifications from immediate and scheduled local notifications",
		arguments: UNNotificationRequest.Delivery.allCases
	)
	func notificationOrigin(delivery: UNNotificationRequest.Delivery) throws -> Void {
		let request = try #require(try UNNotificationRequest(delivery: delivery))

		let response = try #require(try UNNotificationResponse(request: request))

		let notification = AlertNotificationResponse(response: response, completionHandler: {})

		#expect(notification.isRemote == (delivery == .remote))
		#expect(notification.isLocal == (delivery != .remote))
	}

	@Test(
		"Action identifiers are preserved and only the default action is recognized as default",
		arguments: [
			(UNNotificationDefaultActionIdentifier, true),
			(UNNotificationDismissActionIdentifier, false),
			("custom-identifier", false),
		]
	)
	func actionIdentification(actionIdentifier: String, isDefaultAction: Bool) throws -> Void {
		let response = try #require(try UNNotificationResponse(actionIdentifier: actionIdentifier))

		let notification = AlertNotificationResponse(response: response, completionHandler: {})

		#expect(notification.actionIdentifier == actionIdentifier)
		#expect(notification.isDefaultAction == isDefaultAction)
	}

	@Test(
		"Text-input responses preserve the submitted text",
		arguments: ["A reply", ""]
	)
	func textInput(userText: String) throws -> Void {
		let response = try #require(
			try UNTextInputNotificationResponse(actionIdentifier: "reply", userText: userText)
		)

		let notification = AlertNotificationResponse(response: response, completionHandler: {})

		#expect(notification.userText == userText)
	}

	@Test("Responses without text input have no user text")
	func noTextInput() throws -> Void {
		let response = try #require(try UNNotificationResponse())

		let notification = AlertNotificationResponse(response: response, completionHandler: {})

		#expect(notification.userText == nil)
	}

	@Test("Completing a response invokes the supplied handler")
	func completionInvoking() throws -> Void {
		let response = try #require(try UNNotificationResponse())

		var completionCount = 0

		let notification = AlertNotificationResponse(response: response) {
			completionCount += 1
		}

		#expect(completionCount == 0)

		notification.complete()

		#expect(completionCount == 1)
	}
}

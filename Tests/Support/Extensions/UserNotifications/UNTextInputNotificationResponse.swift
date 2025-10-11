import Foundation
import UserNotifications

extension UNTextInputNotificationResponse {
	convenience init?(
		request: UNNotificationRequest = UNNotificationRequest(
			identifier: "test-notification",
			content: UNNotificationContent(),
			trigger: nil
		),
		actionIdentifier: String,
		userText: String
	) throws {
		guard let notification = try UNNotification(request: request) else {
			return nil
		}

		let encoder = NSKeyedArchiver(requiringSecureCoding: true)
		encoder.encode(notification, forKey: "notification")
		encoder.encode(actionIdentifier, forKey: "actionIdentifier")
		encoder.encode(userText, forKey: "userText")
		encoder.finishEncoding()

		let decoder = try NSKeyedUnarchiver(forReadingFrom: encoder.encodedData)
		defer { decoder.finishDecoding() }

		self.init(coder: decoder)
	}
}

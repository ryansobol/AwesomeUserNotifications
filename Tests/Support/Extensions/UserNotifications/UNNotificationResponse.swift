import Foundation
import UserNotifications

extension UNNotificationResponse {
	convenience init?(
		request: UNNotificationRequest = UNNotificationRequest(
			identifier: "test-notification",
			content: UNNotificationContent(),
			trigger: nil
		),
		actionIdentifier: String = UNNotificationDefaultActionIdentifier
	) throws {
		guard let notification = try UNNotification(request: request) else {
			return nil
		}

		let encoder = NSKeyedArchiver(requiringSecureCoding: true)
		encoder.encode(notification, forKey: "notification")
		encoder.encode(actionIdentifier, forKey: "actionIdentifier")
		encoder.finishEncoding()

		let decoder = try NSKeyedUnarchiver(forReadingFrom: encoder.encodedData)
		defer { decoder.finishDecoding() }

		self.init(coder: decoder)
	}
}

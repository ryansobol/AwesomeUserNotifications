import Foundation
import UserNotifications

extension UNNotification {
	convenience init?(
		request: UNNotificationRequest = UNNotificationRequest(
			identifier: "test-notification",
			content: UNNotificationContent(),
			trigger: nil
		),
		date: Date = Date(timeIntervalSince1970: 0)
	) throws {
		// UNNotification has no public request/date initializer.
		// Construct the fixture using undocumented archive keys.
		let encoder = NSKeyedArchiver(requiringSecureCoding: true)
		encoder.encode(request, forKey: "request")
		encoder.encode(date, forKey: "date")
		encoder.finishEncoding()

		let decoder = try NSKeyedUnarchiver(forReadingFrom: encoder.encodedData)
		defer { decoder.finishDecoding() }

		self.init(coder: decoder)
	}
}

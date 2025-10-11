import Foundation
import UserNotifications

extension UNPushNotificationTrigger {
	convenience init?(repeats: Bool) throws {
		let encoder = NSKeyedArchiver(requiringSecureCoding: true)
		encoder.encode(repeats, forKey: "repeats")
		encoder.finishEncoding()

		let decoder = try NSKeyedUnarchiver(forReadingFrom: encoder.encodedData)
		defer { decoder.finishDecoding() }

		self.init(coder: decoder)
	}
}

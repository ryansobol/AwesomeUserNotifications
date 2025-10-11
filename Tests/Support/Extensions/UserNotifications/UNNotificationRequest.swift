import UserNotifications

extension UNNotificationRequest {
	enum Delivery: CaseIterable, Sendable {
		case immediateLocal
		case scheduledLocal
		case remote
	}

	convenience init?(delivery: Delivery) throws {
		let trigger: UNNotificationTrigger?

		switch delivery {
		case .immediateLocal:
			trigger = nil

		case .scheduledLocal:
			trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)

		case .remote:
			guard let pushTrigger = try UNPushNotificationTrigger(repeats: false) else {
				return nil
			}

			trigger = pushTrigger
		}

		self.init(
			identifier: "test-notification",
			content: UNNotificationContent(),
			trigger: trigger
		)
	}
}

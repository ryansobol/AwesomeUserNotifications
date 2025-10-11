import UserNotifications

public struct AlertNotification {
	public let notification: UNNotification

	private let presentationHandler: (UNNotificationPresentationOptions) -> Void

	public var request: UNNotificationRequest {
		return self.notification.request
	}

	public var isRemote: Bool {
		return self.request.trigger is UNPushNotificationTrigger
	}

	public var isLocal: Bool {
		return !self.isRemote
	}

	public var content: UNNotificationContent {
		return self.request.content
	}

	public var userInfo: [AnyHashable: Any] {
		return self.content.userInfo
	}

	internal init(
		notification: UNNotification,
		presentationHandler: @escaping (UNNotificationPresentationOptions) -> Void
	) {
		self.notification = notification
		self.presentationHandler = presentationHandler
	}

	internal func present(with options: UNNotificationPresentationOptions) -> Void {
		return self.presentationHandler(options)
	}
}

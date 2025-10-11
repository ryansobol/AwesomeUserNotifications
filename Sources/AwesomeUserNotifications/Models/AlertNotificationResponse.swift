import UserNotifications

public struct AlertNotificationResponse {
	public let notificationResponse: UNNotificationResponse

	private let completionHandler: () -> Void

	public var notification: UNNotification {
		return self.notificationResponse.notification
	}

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

	public var actionIdentifier: String {
		return self.notificationResponse.actionIdentifier
	}

	public var isDefaultAction: Bool {
		return self.actionIdentifier == UNNotificationDefaultActionIdentifier
	}

	public var userText: String? {
		return (self.notificationResponse as? UNTextInputNotificationResponse)?.userText
	}

	internal init(
		response: UNNotificationResponse,
		completionHandler: @escaping () -> Void
	) {
		self.notificationResponse = response
		self.completionHandler = completionHandler
	}

	internal func complete() -> Void {
		self.completionHandler()
	}
}

import UIKit
import UserNotifications

public struct BackgroundNotification {
	public let userInfo: [AnyHashable: Any]

	private let completionHandler: (UIBackgroundFetchResult) -> Void

	internal init(
		userInfo: [AnyHashable: Any],
		completionHandler: @escaping (UIBackgroundFetchResult) -> Void
	) {
		self.userInfo = userInfo
		self.completionHandler = completionHandler
	}

	internal func complete(with result: UIBackgroundFetchResult) -> Void {
		self.completionHandler(result)
	}
}

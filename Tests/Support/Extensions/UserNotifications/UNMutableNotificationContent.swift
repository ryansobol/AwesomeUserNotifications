import UserNotifications

extension UNMutableNotificationContent {
	convenience init(userInfo: [AnyHashable: Any]) {
		self.init()
		self.userInfo = userInfo
	}
}

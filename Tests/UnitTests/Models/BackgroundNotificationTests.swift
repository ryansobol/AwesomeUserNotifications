import Testing
import UIKit
@testable import AwesomeUserNotifications

@MainActor
@Suite("BackgroundNotification")
struct BackgroundNotificationTests {

	@Test("The background notification preserves its payload")
	func notificationPayload() -> Void {
		let userInfo = ["post_id": "42"]

		let notification = BackgroundNotification(userInfo: userInfo, completionHandler: { _ in })

		#expect(notification.userInfo as? [String: String] == userInfo)
	}

	@Test(
		"Completing a background notification invokes the supplied handler with the fetch result",
		arguments: [UIBackgroundFetchResult.newData, .noData, .failed]
	)
	func completionInvoking(result: UIBackgroundFetchResult) -> Void {
		var capturedFetchResults: [UIBackgroundFetchResult] = []

		let notification = BackgroundNotification(userInfo: [:]) {
			capturedFetchResults.append($0)
		}

		#expect(capturedFetchResults.isEmpty)

		notification.complete(with: result)

		#expect(capturedFetchResults == [result])
	}
}

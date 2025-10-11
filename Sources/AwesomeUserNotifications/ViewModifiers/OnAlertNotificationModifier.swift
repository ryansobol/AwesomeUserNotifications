import SwiftUI

struct OnAlertNotificationModifier: ViewModifier {
	let action: (AlertNotification) async -> UNNotificationPresentationOptions

	func body(content: Content) -> some View {
		content.task {
			for await alertNotification in UserNotificationCenter.alertNotificationsStream {
				let presentationOptions = await self.action(alertNotification)

				alertNotification.present(with: presentationOptions)
			}
		}
	}
}

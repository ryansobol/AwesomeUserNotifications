import SwiftUI

struct OnAlertNotificationResponseModifier: ViewModifier {
	let action: (AlertNotificationResponse) async -> Void

	func body(content: Content) -> some View {
		content.task {
			for await alertNotificationResponse in UserNotificationCenter.alertNotificationResponsesStream {
				await self.action(alertNotificationResponse)

				alertNotificationResponse.complete()
			}
		}
	}
}

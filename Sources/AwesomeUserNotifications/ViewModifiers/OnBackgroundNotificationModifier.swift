import SwiftUI

struct OnBackgroundNotificationModifier: ViewModifier {
	let action: (BackgroundNotification) async -> UIBackgroundFetchResult

	func body(content: Content) -> some View {
		content.task {
			for await backgroundNotification in UserNotificationCenter.backgroundNotificationsStream {
				let fetchResult = await self.action(backgroundNotification)

				backgroundNotification.complete(with: fetchResult)
			}
		}
	}
}

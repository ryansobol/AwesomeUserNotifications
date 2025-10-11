import SwiftUI

struct OnTypedBackgroundNotificationModifier<T: BackgroundNotificationParsable>: ViewModifier {
	let type: T.Type
	let action: (Result<T, Error>) async -> UIBackgroundFetchResult

	func body(content: Content) -> some View {
		content.task {
			for await backgroundNotification in UserNotificationCenter.backgroundNotificationsStream {
				let result = Result {
					try self.type.init(backgroundNotification: backgroundNotification)
				}

				let fetchResult = await self.action(result)

				backgroundNotification.complete(with: fetchResult)
			}
		}
	}
}

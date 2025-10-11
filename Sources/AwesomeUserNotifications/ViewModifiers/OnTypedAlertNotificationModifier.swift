import SwiftUI

struct OnTypedAlertNotificationModifier<T: AlertNotificationParsable>: ViewModifier {
	let type: T.Type
	let action: (Result<T, Error>) async -> UNNotificationPresentationOptions

	func body(content: Content) -> some View {
		content.task {
			for await alertNotification in UserNotificationCenter.alertNotificationsStream {
				let result = Result {
					try self.type.init(alertNotification: alertNotification)
				}

				let presentationOptions = await self.action(result)

				alertNotification.present(with: presentationOptions)
			}
		}
	}
}

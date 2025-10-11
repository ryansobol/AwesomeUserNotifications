import SwiftUI

struct OnTypedAlertNotificationResponseModifier<T: AlertNotificationResponseParsable>: ViewModifier {
	let type: T.Type
	let action: (Result<T, Error>) async -> Void

	func body(content: Content) -> some View {
		content.task {
			for await alertNotificationResponse in UserNotificationCenter.alertNotificationResponsesStream {
				let result = Result {
					try self.type.init(alertNotificationResponse: alertNotificationResponse)
				}

				await self.action(result)

				alertNotificationResponse.complete()
			}
		}
	}
}

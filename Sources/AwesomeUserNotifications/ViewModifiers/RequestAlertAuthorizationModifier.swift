import SwiftUI

struct RequestAlertAuthorizationModifier: ViewModifier {
	let options: UNAuthorizationOptions
	let action: (Result<Bool, Error>) async -> Void

	func body(content: Content) -> some View {
		content.task {
			do {
				let granted = try await UserNotificationCenter.requestAuthorization(with: self.options)

				await self.action(.success(granted))
			} catch {
				await self.action(.failure(error))
			}
		}
	}
}

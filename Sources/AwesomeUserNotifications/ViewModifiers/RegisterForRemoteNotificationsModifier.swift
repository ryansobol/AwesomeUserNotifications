import SwiftUI

struct RegisterForRemoteNotificationsModifier: ViewModifier {
	let action: (Result<String, Error>) async -> Void

	func body(content: Content) -> some View {
		content.task {
			let results = UserNotificationCenter.deviceTokenResultsStream

			UserNotificationCenter.registerForRemoteNotifications()

			for await result in results {
				await self.action(result.map { self.format(deviceToken: $0) })
			}
		}
	}

	/// Converts a device token `Data` object into a hexadecimal string.
	///
	/// Each byte (UInt8) is formatted as a 2-character hexadecimal value (e.g., `255` → `"ff"`).
	/// The resulting string length is always `deviceToken.count * 2`.
	///
	/// The string's capacity is pre-allocated to avoid multiple reallocations during concatenation,
	/// which improves performance when processing device tokens.
	///
	/// - Parameter deviceToken: The raw device token data from APNS registration
	/// - Returns: A lowercase hexadecimal string representation (e.g., `"a1b2c3d4..."`)
	private func format(deviceToken: Data) -> String {
		var formattedDeviceToken = ""

		formattedDeviceToken.reserveCapacity(deviceToken.count * 2)

		for byte in deviceToken {
			formattedDeviceToken += String(format: "%02x", byte)
		}

		return formattedDeviceToken
	}
}

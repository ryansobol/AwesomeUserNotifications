/// Protocol for type-safe parsing of background notifications
///
/// ## Example
/// ```swift
/// import Foundation
///
/// struct SyncNotification: BackgroundNotificationParsable {
///     let url: URL
///
///     init(backgroundNotification: BackgroundNotification) throws {
///         guard let url = backgroundNotification.userInfo["url"] as? String,
///               let parsedURL = URL(string: url) else {
///             throw ParsingError(message: "Missing required field: url")
///         }
///
///         self.url = parsedURL
///     }
/// }
/// ```
public protocol BackgroundNotificationParsable {
	/// Initialize from an background notification
	/// - Parameter backgroundNotification: A background notification for parsing
	/// - Throws: ParsingError or custom error if parsing fails
	init(backgroundNotification: BackgroundNotification) throws
}

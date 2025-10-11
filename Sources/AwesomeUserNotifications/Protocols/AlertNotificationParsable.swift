/// Protocol for type-safe parsing of alert notifications
///
/// ## Example
/// ```swift
/// struct PostNotification: AlertNotificationParsable {
///     let postId: Int
///     let title: String
///
///     init(alertNotification: AlertNotification) throws {
///         guard let postId = alertNotification.userInfo["post_id"] as? String,
///               let parsedPostId = Int(postId) else {
///             throw ParsingError(message: "Missing required field: post_id")
///         }
///
///         self.postId = parsedPostId
///
///         self.title = alertNotification.content.title
///     }
/// }
/// ```
public protocol AlertNotificationParsable {
	/// Initialize from an alert notification
	/// - Parameter alertNotification: An alert notification for parsing
	/// - Throws: ParsingError or custom error if parsing fails
	init(alertNotification: AlertNotification) throws
}

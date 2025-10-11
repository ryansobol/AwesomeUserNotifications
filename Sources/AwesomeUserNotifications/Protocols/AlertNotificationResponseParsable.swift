/// Protocol for type-safe parsing of alert notification responses
///
/// ## Example
/// ```swift
/// struct PostNotification: AlertNotificationResponseParsable {
///     let postId: Int
///     let title: String
///
///     init(alertNotificationResponse: AlertNotificationResponse) throws {
///         guard let postId = alertNotificationResponse.userInfo["post_id"] as? String,
///               let parsedPostId = Int(postId) else {
///             throw ParsingError(message: "Missing required field: post_id")
///         }
///
///         self.postId = parsedPostId
///
///         self.title = alertNotificationResponse.content.title
///     }
/// }
/// ```
public protocol AlertNotificationResponseParsable {
	/// Initialize from an alert notification response
	/// - Parameter alertNotification: An alert notification response for parsing
	/// - Throws: ParsingError or custom error if parsing fails
	init(alertNotificationResponse: AlertNotificationResponse) throws
}

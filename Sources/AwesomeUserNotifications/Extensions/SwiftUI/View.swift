import SwiftUI

extension View {
	// MARK: - Alert Notification Handlers

	/// Handle alert notifications in foreground
	///
	/// Return how to present the notification.
	///
	/// ## Example
	/// ```swift
	/// .onAlertNotification { alertNotification in
	///     await notifyTelemetry(for: alertNotification)
	///     return [.banner, .sound]
	/// }
	/// ```
	public func onAlertNotification(
		_ action: @escaping (AlertNotification) async -> UNNotificationPresentationOptions
	) -> some View {
		self.modifier(OnAlertNotificationModifier(action: action))
	}

	/// Handle typed alert notifications in foreground
	///
	/// Return how to present the notification.
	///
	/// ## Example
	/// ```swift
	/// .onAlertNotification(PostNotification.self) { result in
	///     switch result {
	///     case .success(let postNotification):
	///         await notifyTelemetry(for: postNotification)
	///         return [.banner, .sound]
	///
	///     case .failure(let error):
	///         print("Parse error: \(error)")
	///         return []
	///     }
	/// }
	/// ```
	public func onAlertNotification<T: AlertNotificationParsable>(
		_ type: T.Type,
		_ action: @escaping (Result<T, Error>) async -> UNNotificationPresentationOptions
	) -> some View {
		self.modifier(OnTypedAlertNotificationModifier(type: type, action: action))
	}

	// MARK: - Alert Notification Response Handlers

	/// Handle user responses to alert notifications
	///
	/// ## Example
	/// ```swift
	/// .onAlertNotificationResponse { alertNotificationResponse in
	///     self.post = await loadPost(for: alertNotificationResponse)
	/// }
	/// ```
	public func onAlertNotificationResponse(
		_ action: @escaping (AlertNotificationResponse) async -> Void
	) -> some View {
		self.modifier(OnAlertNotificationResponseModifier(action: action))
	}


	/// Handle typed alert notification responses
	///
	/// ## Example
	/// ```swift
	/// .onAlertNotificationResponse(PostNotification.self) { result in
	///     switch result {
	///     case .success(let postNotification):
	///         self.post = await loadPost(for: postNotification)
	///
	///     case .failure(let error):
	///         print("Parse error: \(error)")
	///     }
	/// }
	/// ```
	public func onAlertNotificationResponse<T: AlertNotificationResponseParsable>(
		_ type: T.Type,
		_ action: @escaping (Result<T, Error>) async -> Void
	) -> some View {
		self.modifier(OnTypedAlertNotificationResponseModifier(type: type, action: action))
	}

	// MARK: - Background Notification Handlers

	/// Handle background notifications
	///
	/// Return the backround fetch result.
	///
	/// ## Example
	/// ```swift
	/// .onBackgroundNotification { backgroundNotification in
	///     self.data = await fetchData(for: backgroundNotification)
	///     return .newData
	/// }
	/// ```
	public func onBackgroundNotification(
		_ action: @escaping (BackgroundNotification) async -> UIBackgroundFetchResult
	) -> some View {
		self.modifier(OnBackgroundNotificationModifier(action: action))
	}

	/// Handle typed background notifications
	///
	/// Return the background fetch result.
	///
	/// ## Example
	/// ```swift
	/// .onBackgroundNotification(SyncNotification.self) { result in
	///     switch result {
	///     case .success(let syncNotification):
	///         self.data = await fetchData(for: syncNotification)
	///         return .newData
	///
	///     case .failure(let error):
	///         print("Parse error: \(error)")
	///         return .failed
	///     }
	/// }
	/// ```
	public func onBackgroundNotification<T: BackgroundNotificationParsable>(
		_ type: T.Type,
		_ action: @escaping (Result<T, Error>) async -> UIBackgroundFetchResult
	) -> some View {
		self.modifier(OnTypedBackgroundNotificationModifier(type: type, action: action))
	}

	// MARK: - Register Remote Notifications

	/// Register for remote notifications (alert or background)
	///
	/// Provides device token needed to receive remote notifications from your server.
	/// Required for both remote alerts and background notifications.
	///
	/// ## Example
	/// ```swift
	/// .registerForRemoteNotifications { result in
	/// 	  switch result {
	///     case .success(let deviceToken):
	///         await ProviderClient.register(deviceToken)
	///
	///     case .failure(let error):
	///         print("Registration error: \(error)")
	///     }
	/// }
	/// ```
	///
	/// - Parameter action: Called with each APNs device token (hex string) or registration error
	public func registerForRemoteNotifications(
		_ action: @escaping (Result<String, Error>) async -> Void
	) -> some View {
		self.modifier(RegisterForRemoteNotificationsModifier(action: action))
	}

	// MARK: - Request Alert Authorization

	/// Request authorization to show alert notifications
	///
	/// Required for local and remote alert notifications.
	/// Not needed for background notifications.
	///
	/// ## Example
	/// ```swift
	/// .requestAlertAuthorization { result in
	///     switch result {
	///     case .success(let isGranted):
	///         await notifyTelemetry(status: isGranted ? "Authorized" : "Denied")
	///
	///     case .failure(let error):
	///         print("Error: \(error)")
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - options: Authorization options (alert, sound, badge)
	///   - action: Called with authorization result
	public func requestAlertAuthorization(
		options: UNAuthorizationOptions = [.alert, .sound, .badge],
		_ action: @escaping (Result<Bool, Error>) async -> Void
	) -> some View {
		self.modifier(RequestAlertAuthorizationModifier(options: options, action: action))
	}
}

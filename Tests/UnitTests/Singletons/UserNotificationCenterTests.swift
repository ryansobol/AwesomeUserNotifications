import Foundation
import Testing
import UserNotifications
@testable import AwesomeUserNotifications

@MainActor
@Suite("UserNotificationCenter", .timeLimit(.minutes(1)))
struct UserNotificationCenterTests {

	@Test("The initial authorization status is published and each activation publishes a fresh read, even when unchanged")
	func initialStatusAndActivationUpdates() async throws -> Void {
		let notificationCenter = NotificationCenter()

		let activationName = Notification.Name("activation")

		let expectedStatuses = Array<UNAuthorizationStatus>([
			.notDetermined,
			.authorized,
			.denied,
			.denied,
		])

		var readCount = 0

		let stream = UserNotificationCenter.makeAuthorizationStatusStream(
			activations: notificationCenter.notifications(named: activationName),
			readAuthorizationStatus: {
				readCount += 1

				return expectedStatuses[readCount - 1]
			}
		)

		var iterator = stream.makeAsyncIterator()

		try #require(await iterator.next() == .notDetermined)

		#expect(readCount == 1)

		for (index, status) in expectedStatuses.dropFirst().enumerated() {
			notificationCenter.post(name: activationName, object: nil)

			try #require(await iterator.next() == status)

			#expect(readCount == index + 2)
		}
	}

	@Test("Cancelling the consumer cancels a pending authorization-status read and ends delivery")
	func cancellationDuringStatusRead() async throws -> Void {
		let notificationCenter = NotificationCenter()
		let activationName = Notification.Name("activation")
		let (readCancellationStates, continuation) = AsyncStream<Bool>.makeStream()

		let stream = UserNotificationCenter.makeAuthorizationStatusStream(
			activations: notificationCenter.notifications(named: activationName),
			readAuthorizationStatus: {
				continuation.yield(Task.isCancelled)

				// Keep the read suspended until its task is cancelled.
				let pendingRead = AsyncStream<Void> { _ in }

				for await _ in pendingRead {}

				continuation.yield(Task.isCancelled)
				continuation.finish()

				return .authorized
			}
		)

		let consumer = Task { await Array(stream) }

		defer { consumer.cancel() }

		var iterator = readCancellationStates.makeAsyncIterator()

		try #require(await iterator.next() == false)

		consumer.cancel()

		let statuses = await consumer.value

		#expect(statuses.isEmpty)
		#expect(await iterator.next() == true)
	}
}

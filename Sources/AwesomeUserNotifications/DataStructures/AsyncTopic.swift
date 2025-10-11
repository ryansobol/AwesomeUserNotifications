import Foundation

final class AsyncTopic<Element: Sendable> {
	private var continuationForUUID: [UUID: AsyncStream<Element>.Continuation] = [:]

	var subscriptionCount: Int {
		return self.continuationForUUID.count
	}

	deinit {
		for continuation in self.continuationForUUID.values {
			continuation.finish()
		}
	}

	@discardableResult
	func publish(_ value: Element) -> [AsyncStream<Element>.Continuation.YieldResult] {
		var yieldResults: [AsyncStream<Element>.Continuation.YieldResult] = []

		yieldResults.reserveCapacity(self.continuationForUUID.count)

		for continuation in self.continuationForUUID.values {
			let yieldResult = continuation.yield(value)

			yieldResults.append(yieldResult)
		}

		return yieldResults
	}

	func subscribe(
		bufferingPolicy limit: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded
	) -> AsyncStream<Element> {
		let (stream, continuation) = AsyncStream<Element>.makeStream(bufferingPolicy: limit)
		let uuid = UUID()

		self.continuationForUUID[uuid] = continuation

		continuation.onTermination = { [weak self] _ in
			Task { @MainActor in
				self?.removeContinuation(for: uuid)
			}
		}

		return stream
	}

	private func removeContinuation(for uuid: UUID) -> Void {
		self.continuationForUUID.removeValue(forKey: uuid)
	}
}

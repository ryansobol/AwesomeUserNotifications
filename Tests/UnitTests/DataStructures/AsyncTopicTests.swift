import Testing
@testable import AwesomeUserNotifications

@MainActor
@Suite("AsyncTopic", .timeLimit(.minutes(1)))
struct AsyncTopicTests {

	@Test("Publishing without subscribers returns no results")
	func noSubscribers() -> Void {
		let topic = AsyncTopic<Int>()

		#expect(topic.publish(42).isEmpty)
	}

	/// Creates a topic scoped to synchronous test setup.
	///
	/// The helper releases its reference after `action` returns. Provided `action`
	/// does not retain the topic, `AsyncTopic.deinit` finishes each stream.
	/// Returned streams can then deliver their buffered values and end, allowing
	/// `await Array(stream)` to complete without keeping the publisher alive.
	private func withAsyncTopic<T>(_ action: (AsyncTopic<Int>) -> T) -> T {
		return action(AsyncTopic<Int>())
	}

	@Test("The default buffering policy preserves every value in publication order")
	func publicationOrder() async -> Void {
		let values = Array(0..<100)

		let stream = withAsyncTopic { topic in
			let stream = topic.subscribe()

			for value in values {
				topic.publish(value)
			}

			return stream
		}

		#expect(await Array(stream) == values)
	}

	@Test("Every subscriber receives every publication")
	func broadcastDelivery() async -> Void {
		let values = [1, 2, 3]

		let streams = withAsyncTopic { topic in
			let stream1 = topic.subscribe()
			let stream2 = topic.subscribe()

			for value in values {
				let results = topic.publish(value)

				#expect(results.count == 2)
			}

			return (stream1, stream2)
		}

		#expect(await Array(streams.0) == values)
		#expect(await Array(streams.1) == values)
	}

	@Test("Late subscribers receive only subsequent publications")
	func lateSubscription() async -> Void {
		let streams = withAsyncTopic { topic in
			topic.publish(0)

			let stream1 = topic.subscribe()

			topic.publish(1)

			let stream2 = topic.subscribe()

			topic.publish(2)
			topic.publish(3)

			return (stream1, stream2)
		}

		#expect(await Array(streams.0) == [1, 2, 3])
		#expect(await Array(streams.1) == [2, 3])
	}

	@Test(
		"The newest-value buffering policy keeps the most recent values within capacity and reports dropped values",
		arguments: [0, 1, 3]
	)
	func bufferingNewest(capacity: Int) async throws -> Void {
		let values = [1, 2, 3, 4]

		let (stream, results) = withAsyncTopic { topic in
			let stream = topic.subscribe(bufferingPolicy: .bufferingNewest(capacity))

			let results = values.flatMap { topic.publish($0) }

			return (stream, results)
		}

		try #require(results.count == values.count)

		for (index, result) in results.enumerated() {
			if index < capacity {
				guard case .enqueued(let remaining) = result else {
					Issue.record(
						"Expected an enqueued result before capacity was reached, but received \(result)."
					)

					continue
				}

				#expect(remaining == capacity - index - 1)
			}
			else {
				guard case .dropped(let value) = result else {
					Issue.record(
						"Expected publishing at capacity to report a dropped value, but received \(result)."
					)

					continue
				}

				#expect(value == values[index - capacity])
			}
		}

		#expect(await Array(stream) == Array(values.suffix(capacity)))
	}

	@Test(
		"The oldest-value buffering policy keeps the earliest values within capacity and reports dropped values",
		arguments: [0, 1, 3]
	)
	func bufferingOldest(capacity: Int) async throws -> Void {
		let values = [1, 2, 3, 4]

		let (stream, results) = withAsyncTopic { topic in
			let stream = topic.subscribe(bufferingPolicy: .bufferingOldest(capacity))

			let results = values.flatMap { topic.publish($0) }

			return (stream, results)
		}

		try #require(results.count == values.count)

		for (index, result) in results.enumerated() {
			if index < capacity {
				guard case .enqueued(let remaining) = result else {
					Issue.record(
						"Expected an enqueued result before capacity was reached, but received \(result)."
					)

					continue
				}

				#expect(remaining == capacity - index - 1)
			}
			else {
				guard case .dropped(let value) = result else {
					Issue.record(
						"Expected publishing at capacity to report a dropped value, but received \(result)."
					)

					continue
				}

				#expect(value == values[index])
			}
		}

		#expect(await Array(stream) == Array(values.prefix(capacity)))
	}

	@Test("Subscribers use independent buffering policies")
	func independentBufferingPolicies() async -> Void {
		let streams = withAsyncTopic { topic in
			let unboundedStream = topic.subscribe(bufferingPolicy: .unbounded)
			let oldestStream = topic.subscribe(bufferingPolicy: .bufferingOldest(2))
			let newestStream = topic.subscribe(bufferingPolicy: .bufferingNewest(2))

			topic.publish(1)
			topic.publish(2)

			let results = topic.publish(3)

			#expect(results.count == 3)

			let enqueuedResults = results.filter {
				return if case .enqueued = $0 { true } else { false }
			}

			#expect(enqueuedResults.count == 1)

			let sortedResults: [Int] = results.compactMap {
				return if case .dropped(let value) = $0 { value } else { nil }
			}.sorted()

			#expect(sortedResults == [1, 3])

			topic.publish(4)

			return (unboundedStream, oldestStream, newestStream)
		}

		#expect(await Array(streams.0) == [1, 2, 3, 4])
		#expect(await Array(streams.1) == [1, 2])
		#expect(await Array(streams.2) == [3, 4])
	}

	@Test("Cancelling a consumer removes its subscription without affecting other subscribers")
	func cancellationIsolation() async throws -> Void {
		let topic = AsyncTopic<Int>()

		let cancelledStream = topic.subscribe()
		let activeStream = topic.subscribe()

		#expect(topic.subscriptionCount == 2)

		let consumer = Task {
			for await _ in cancelledStream {}
		}

		consumer.cancel()

		// Wait for the consuming loop to exit after requesting cancellation.
		await consumer.value

		// Subscription cleanup runs in a separate task after stream termination.
		while topic.subscriptionCount != 1 {
			try Task.checkCancellation()

			await Task.yield()
		}

		topic.publish(42)

		let received = await activeStream.first { @Sendable _ in true }

		#expect(received == 42)
	}

	@Test("Releasing the topic finishes all streams")
	func streamCompletion() async -> Void {
		let streams = withAsyncTopic { ($0.subscribe(), $0.subscribe()) }

		#expect(await Array(streams.0).isEmpty)
		#expect(await Array(streams.1).isEmpty)
	}

	@Test("Streams do not retain the topic")
	func topicLifetime() async throws -> Void {
		weak var releasedTopic: AsyncTopic<Int>?

		let _ = withAsyncTopic { topic in
			releasedTopic = topic

			return topic.subscribe()
		}

		#expect(releasedTopic == nil)
	}
}

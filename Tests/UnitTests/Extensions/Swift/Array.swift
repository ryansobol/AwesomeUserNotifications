extension Array {
	nonisolated init(_ stream: AsyncStream<Element>) async {
		self = await stream.reduce(into: []) { values, value in
			values.append(value)
		}
	}
}

public struct ParsingError: Error {
	public let message: String

	public init(message: String) {
		self.message = message
	}
}

extension ParsingError: CustomStringConvertible {
	public var description: String {
		message
	}
}

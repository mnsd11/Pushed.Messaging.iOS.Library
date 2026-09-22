import Foundation

/// Builds a W3C `traceparent` header value for an outgoing request.
///
/// If `incomingTraceId` (a bare 32-hex trace id, e.g. from a push's
/// `mfTraceId`/`mf-trace-id`) is provided and valid, the outgoing span is made
/// a child of that trace so the request correlates server-side with whatever
/// originated it. Otherwise a fresh root trace is started.
///
/// Not backed by the OpenTelemetry SDK (unlike the Android/Dart siblings) —
/// this library ships via CocoaPods, and `opentelemetry-swift` isn't
/// available there without risking the publish pipeline. The output format
/// and propagation semantics are identical to what that SDK would produce.
enum TraceContext {
    private static func randomHex(byteCount: Int) -> String {
        // SystemRandomNumberGenerator (what UInt8.random uses) is cryptographically
        // secure on Apple platforms, and a trace id isn't a secret anyway — so this
        // avoids pulling in the Security framework just for SecCopyRandomBytes.
        let bytes = (0..<byteCount).map { _ in UInt8.random(in: 0...255) }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func isValidTraceId(_ traceId: String) -> Bool {
        traceId.count == 32
            && traceId.range(of: "^[0-9a-f]{32}$", options: .regularExpression) != nil
            && traceId != String(repeating: "0", count: 32)
    }

    static func traceParentHeaders(incomingTraceId: String? = nil) -> [String: String] {
        let traceId: String
        if let incoming = incomingTraceId, isValidTraceId(incoming) {
            traceId = incoming
        } else {
            traceId = randomHex(byteCount: 16)
        }
        let spanId = randomHex(byteCount: 8)
        return ["traceparent": "00-\(traceId)-\(spanId)-01"]
    }
}

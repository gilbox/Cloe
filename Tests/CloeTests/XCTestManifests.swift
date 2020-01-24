import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(CloeTests.allTests),
    testCase(RetainedPublisherActionTests.allTests),
    testCase(PublisherActionTests.allTests),
    testCase(PublisherStatusDispatcherTests.allTests),
    testCase(PublisherStateDispatcherTests.allTests),
    testCase(HandleCleanupTests.allTests),
    testCase(CombinedReducersTests.allTests),
  ]
}
#endif

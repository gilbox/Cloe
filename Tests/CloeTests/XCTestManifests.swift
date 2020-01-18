import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(RetainedPublisherActionTests.allTests),
    testCase(PublisherActionTests.allTests),
  ]
}
#endif

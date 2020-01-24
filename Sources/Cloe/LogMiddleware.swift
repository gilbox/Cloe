// Created by Gil Birman on 1/23/20.

import Foundation
import os.log

/// Middleware that logs every action with os_log.
/// Customize the log message by conforming an action to `CustomStringConvertible`.
/// When using the Console.app to view logs, filter on the category (default is "Cloe")
/// - Parameter category: The os_log category
/// - Parameter logType: The os_log logging level
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public func createLogMiddleware<State>(category: String = "Cloe", logType: OSLogType = .info) -> Middleware<State> {
  let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: category)

  return { (fullDispatch, getState, nextDispatch) in
    { action in
      os_log("%s", log: log, type: logType, String(describing: action))
      nextDispatch(action)
    }
  }
}

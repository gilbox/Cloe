
# Update instructions:
# 1) push tag
#    git tag x.y.z
#    git push origin --tags
#
# 2) lint
#    pod spec lint Cloe.podspec
#
# 3) publish new version
#    pod trunk push

Pod::Spec.new do |spec|

  spec.name         = "Cloe"
  spec.version      = "0.3.0"
  spec.summary      = "Cloe is Redux on Combine for SwiftUI with excellent feng shui."

  spec.description  = <<-DESC
  Heavily inspired by ReSwift, but Cloe does away with the bespoke pub/sub system
  and instead uses Combine. The composeMiddleware code is easier to read than ReSwift
  and the Middleware type is simpler making it easier to write your own Middleware.
  Comes with both the classic Thunk middleware, as well as a middleware specifically
  for Combine pipelines.
                   DESC

  spec.homepage     = "https://github.com/gilbox/Cloe"

  # TODO
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  spec.license      = { :type => "MIT", :file => "LICENSE" }


  spec.author             = { "Gil Birman" => "birmangil@gmail.com" }

  # TODO
  # spec.social_media_url   = "https://twitter.com/Gil Birman"

  spec.platform     = :ios, :osx, :tvos, :watchos

  spec.ios.deployment_target = "13"
  spec.osx.deployment_target = "10.15"
  spec.watchos.deployment_target = "6"
  spec.tvos.deployment_target = "13"

  spec.source       = { :git => "https://github.com/gilbox/Cloe.git", :tag => "#{spec.version}" }


  spec.swift_versions = ["5.0", "5.1"]
  spec.source_files  = "Sources", "Sources/**/*"

  # TODO
  # spec.exclude_files = "Classes/Exclude"

  # spec.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"

  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"

  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

end

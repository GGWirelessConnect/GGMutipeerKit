
Pod::Spec.new do |spec|

  spec.name         = "GGMutipeerKit"
  spec.version      = "0.0.1"
  spec.summary      = "GGMutipeerKit是基于封装的小框架。支持函数式语法糖，让你的代码更简练。\nGGMutipeer is a small framework based on the package. Support functional syntactic sugar to make your code more concise."

  spec.description  = <<-DESC
                    This is a framework base on MutipeerConnectivity, supported on iOS.
                   DESC

  spec.homepage     = "https://github.com/itmarsung/GGMutipeerKit"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "marsung" => "itmarsung@163.com" }

  spec.platform     = :ios, "7.0"

  spec.requires_arc    = true

  spec.source       = { :git => "https://github.com/itmarsung/GGMutipeerKit.git", :tag => spec.version }

  spec.source_files = 'framework/*.{h,m}'

end

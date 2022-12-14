require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = package["name"]
  s.version      = package["version"]
  s.description  = package["description"]
  s.summary      = package["description"]
  s.license      = "MIT"
  s.homepage     = 'https://uqu.do'
  s.platforms    = { :ios => "9.0" }
  s.source_files = "ios/*.{h,c,m,swift}"
  s.requires_arc = true
  s.source       = { :http => "https://uqu.do" }
  s.author       = { 'Uqudo' => 'hello@uqu.do' }
  s.dependency "React"
  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '${PODS_ROOT}/../' }
end


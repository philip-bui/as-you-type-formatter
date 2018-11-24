Pod::Spec.new do |s|
  s.name = 'AsYouTypeFormatter'
  s.version = '1.0.0'
  s.license= { :type => 'MIT', :file => 'LICENSE' }
  s.summary = 'As You Type Formatter.'
  s.description = 'Format text as you type, given certain character prefixes such as hashtags and mentions.'
  s.homepage = 'https://github.com/philip-bui/as-you-type-formatter'
  s.author = { 'Philip Bui' => 'philip.bui.developer@gmail.com' }
  s.source = { :git => 'https://github.com/philip-bui/as-you-type-formatter.git', :tag => s.version }
  s.documentation_url = 'https://github.com/philip-bui/as-you-type-formatter'

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'Sources/*.swift', 'Sources/*/*.swift'
  s.swift_version = '4.2'
end

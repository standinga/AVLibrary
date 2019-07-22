Pod::Spec.new do |s|

  s.name         = "AVLibrary"
  s.version      = "0.0.8"
  s.summary      = "A wrapper / manager for AVSession camera and microphone"
  s.description  = "Will be nice"

  s.homepage     = "https://borama.co"
  s.license      = "MIT"

  s.author             = { "michal bojanowicz" => "boramaapps@gmail.com" }
  s.source       = { :path => '.' }
  s.source_files  = "AVLibrary"
  s.exclude_files = "Classes/Exclude"
  s.resources    = ['AVLibrary/*.png', 'AVLibrary/*.jpg']
end

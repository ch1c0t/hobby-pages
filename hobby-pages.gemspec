Gem::Specification.new do |g|
  g.name    = 'hobby-pages'
  g.files   = `git ls-files`.split($/)
  g.version = '0.0.0'
  g.summary = 'A Hobby app to return a bunch of HTML pages from a directory.'
  g.authors = ['Anatoly Chernow']

  g.add_dependency 'hobby'
  g.add_dependency 'tilt'
  g.add_dependency 'slim'
end

Gem::Specification.new do |s|
  s.author = 'Yancy Ribbens'
  s.name = 'yellow_daystar'
  s.files = ['lib/yellow_daystar.rb']
  s.summary = 'implements the verifiable credentials data model'
  s.version = '1.0.0'
  s.add_development_dependency 'json-ld'
  s.add_development_dependency 'jwt'
  s.add_development_dependency 'rbnacl'
  s.add_development_dependency 'merkle-hash-tree'
end

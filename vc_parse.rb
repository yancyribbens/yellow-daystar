#!/usr/local/bin/ruby
require 'yellow_daystar'
require 'open-uri'

if STDIN.tty?
  puts 'vc_parse.rb < vc.json-ld'
else
  data = JSON.parse(STDIN.read)
  if ARGV.include?('--issue')
    vc = YellowDaystar::VerifiableCredential.new(
     [ { iri: 'https://www.w3.org/2018/credentials/examples/v1', path: 'example_context' } ]
    )
    out = vc.consume(data)
    puts JSON.pretty_generate(out)
  else ARGV.include?('--presentation')
    puts "presentation TODO"
  end
end


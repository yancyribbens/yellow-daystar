require 'json/ld'
require 'pry'

module YellowDaystar
  class VerifiableCredential

    ### initialize() accepts an array of context hashes to cache
    ### example:
    ### [ { iri: 'https://www.w3.org/2018/credentials/examples/v1', path: 'example_context' } ]

    def initialize(contexts = [])
      base = JSON::LD::Context.new().parse('/usr/src/app/base_context')
      JSON::LD::Context.add_preloaded('https://www.w3.org/2018/credentials/v1', base)

      #contexts.each do |context|
        #parsed_context = JSON::LD::Context.new().parse(context[:path])
        #JSON::LD::Context.add_preloaded(context[:iri], parsed_context)
      #end
    end

    def produce(context:, id:, type:, credential_subject:, proof:)
      {
        "@context": [
          "https://www.w3.org/2018/credentials/v1",
          context
        ],
        "id": id,
        type: ["VerifiableCredential", type],
        "credentialSubject": credential_subject,
        "proof": proof
      }
    end

    def consume(json)
      #JSON::LD::API.expand(json)
      json
    end
  end
end

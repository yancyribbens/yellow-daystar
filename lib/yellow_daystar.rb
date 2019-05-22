require 'json/ld'
require 'pry'

class VerifiableCredentialParseError < StandardError
  def initialize(msg="Parse Error")
    super
  end
end

module YellowDaystar
  BASE_CONTEXT = "https://www.w3.org/2018/credentials/v1"
  VERIFIABLE_CREDENTIAL_TYPE = "VerifiableCredential"

  class VerifiableCredential

    ### initialize() accepts an array of context hashes to cache
    ### example:
    ### [ { iri: 'https://www.w3.org/2018/credentials/examples/v1', path: 'example_context' } ]

    def initialize(contexts = [])
      #base = JSON::LD::Context.new().parse('/usr/src/app/base_context')
      #JSON::LD::Context.add_preloaded('https://www.w3.org/2018/credentials/v1', base)

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
    
    def validate(credential)
      context = credential["@context"]
      type = credential["type"]

      if context.first != BASE_CONTEXT
        raise VerifiableCredentialParseError.new("first context must be #{BASE_CONTEXT}")
      end
      if context.length < 2
        raise VerifiableCredentialParseError.new("Missing context")
      end
      if type.kind_of?(Array) && (type.include? VERIFIABLE_CREDENTIAL_TYPE)
        if type.length < 2
          raise VerifiableCredentialParseError.new(
            "Missing type. A VerifiableCredential must have a type."
          )
        end
      else
        raise VerifiableCredentialParseError.new(
          "Missing type. A Verifiable Credential must have a type of VerifiableCredential"
        )
      end
    end

    def consume(credential)
      JSON::LD::API.expand(credential)
      validate(credential)
      credential
    end
  end
end

require 'json/ld'
require 'pry'
require 'rbnacl'

#TODO simplify validation, possibly with grammer or another gem or json-ld schema

#TODO subclass these so that the parent class is the same and the child class bubles
# exception information specific to the exception
class VerifiableCredentialParseError < StandardError
  def initialize(msg="Parse Error")
    super
  end
end


class VerifiablePresentationParseError < StandardError
  def initialize(msg="Parse Error")
    super
  end
end

module YellowDaystar
  BASE_CONTEXT = "https://www.w3.org/2018/credentials/v1"
  DEPRECATED_CONTEXT = "https://raw.githubusercontent.com/w3c/vc-data-model/24cf5e97e1a41786e9e4dbfa4f9f264c4c41e537/contexts/credentials/v1"
  VERIFIABLE_CREDENTIAL_TYPE = "VerifiableCredential"

  class VerifiablePresentation

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

    def validate(presentation)
      unless subject = presentation["verifiableCredential"]
        raise VerifiablePresentationParseError.new("Missing VerifiablePresentation")
      end
      unless subject = presentation["proof"]
        raise VerifiablePresentationParseError.new("Missing proof")
      end
    end

    def consume(presentation)
      JSON::LD::API.expand(presentation)
      validate(presentation)
      presentation
    end
  end

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

    def sign(credential)
      private_key = RbNaCl::Signatures::Ed25519::SigningKey.new(RbNaCl::Random.random_bytes(32))
      public_key = private_key.verify_key
      token = JWT.encode credential, private_key, 'ED25519'
      proof = {
        "type" => "ED25519",
        "created" => "2017-06-18T21:19:10Z",
        "proofPurpose" => "assertionMethod",
        "public_key" => public_key.to_s,
        "jws" => token
      }
      credential.merge("proof" => proof)
    end

    def verify(proof, key)
      jws = proof["jws"]
      pub_key = proof["public_key"]
      private_key = RbNaCl::Signatures::Ed25519::SigningKey.new(key)
      raise 'invalid pub key' if pub_key != private_key.verify_key.to_s
      JWT.decode jws, private_key.verify_key, true, { algorithm: 'ED25519' }
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

      if context.first != BASE_CONTEXT && context.first != DEPRECATED_CONTEXT
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
      if subject = credential["credentialSubject"]
        #TODO
        #credentil subject id must be a uri
      else
        raise VerifiableCredentialParseError.new(
          "Missing credentialSubject"
        )
      end
      if issuer = credential["issuer"]
        unless issuer =~ URI::DEFAULT_PARSER.make_regexp
          raise VerifiableCredentialParseError.new("Malformed issuer: bad URI: #{issuer}")
        end
      else credential["issuer"]
        raise VerifiableCredentialParseError.new(
          "Missing issuer"
        )
      end
      if issue_date = credential["issuanceDate"]
        begin
          Time.iso8601(issue_date)
        rescue ArgumentError
          raise VerifiableCredentialParseError.new(
            "invalid date: #{issue_date}"
          )
        end
      else
        raise VerifiableCredentialParseError.new("Missing issuanceDate")
      end
      if expiration_date = credential["expirationDate"]
        begin
          Time.iso8601(expiration_date)
        rescue ArgumentError
          raise VerifiableCredentialParseError.new(
            "invalid date: #{expiration_date}"
          )
        end
      end
      if status = credential["credentialStatus"]
        ["type", "id"].each do |required|
          unless status.key?(required)
            raise VerifiableCredentialParseError.new(
              "CredentialStatus must include a #{required}"
            )
          end
        end
      end
      if proof = credential["proof"]

        # if this is a ZKP which is of type AnonCredV1 then credentialSchema is required
        if proof["type"] == "AnonCredv1" || proof["type"] == "CLSignature2019"
          if credential_schema = credential["credentialSchema"]
            if credential_schema.kind_of?(Array)
              credential_schema.each do |item|
                ["id", "type"].each do |property|
                  unless item[property]
                    raise VerifiableCredentialParseError.new("Missing credentialSchema #{property}")
                  end
                end
              end
            else
              ["id", "type"].each do |property|
                unless credential_schema[property]
                  raise VerifiableCredentialParseError.new("Missing credentialSchema #{property}")
                end
              end
            end
          else
            raise VerifiableCredentialParseError.new("Missing credentialSchema")
          end
        end

        unless proof["type"]
          raise VerifiableCredentialParseError.new(
            "Missing proof type"
          )
        end
      else
        raise VerifiableCredentialParseError.new("Missing proof")
      end
    end

    def consume(credential)
      JSON::LD::API.expand(credential)
      validate(credential)
      credential
    end
  end
end

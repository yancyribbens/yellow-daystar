require 'json/ld'

module YellowDaystar
  class VerifiableCredential
    def self.produce(context:, id:, type:, credential_subject:, proof:)
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

    def self.consume(json)
      JSON::LD::API.expand(json)
    end
  end
end

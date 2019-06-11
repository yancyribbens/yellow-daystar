require 'minitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'
require 'yellow_daystar'
require 'jwt'
require 'pry'

class YellowDaystarTest < Minitest::Test
  BASE_CONTEXT = "https://www.w3.org/2018/credentials/v1"
  VERIFIABLE_CREDENTIAL_TYPE = "VerifiableCredential"

  def deep_transform_keys(hash)
    result = {}
    hash.each do |key, value|
      result[key.to_s] = value.is_a?(Hash) ? deep_transform_keys(value) : value
    end
    result
  end

  def sample_presentation
    deep_transform_keys(
      {
        "@context" => [
          "https://www.w3.org/2018/credentials/v1",
          "https://www.w3.org/2018/credentials/examples/v1"
        ],
        "id" => "urn:uuid:3978344f-8596-4c3a-a978-8fcaba3903c5",
        "type" => ["VerifiablePresentation", "CredentialManagerPresentation"],
        "verifiableCredential" => [{
          "id" => "http://example.edu/credentials/3732",
          "type" => ["VerifiableCredential", "UniversityDegreeCredential"],
          "issuer" => "https://example.edu/issuers/14",
          "issuanceDate" => "2010-01-01T19:23:24Z",
          "credentialSubject" => {
            "id" => "did:example:ebfeb1f712ebc6f1c276e12ec21",
            "degree" => {
              "type" => "BachelorDegree",
              "name" => "<span lang='fr-CA'>Baccalauréat en musiques numériques</span>"
            }
          },
          "proof" => [{
            "type" => "example"
          }]
        }],
        "proof" => [{
          "type" => "example"
        }]
      }
    )
  end

  def sample_zkp
    {
      "@context" => [
        BASE_CONTEXT,
        "https://www.w3.org/2018/credentials/examples/v1"
      ],
      "type" => ["VerifiableCredential", "UniversityDegreeCredential"],
      "credentialSchema" => {
        "id" => "did:example:cdf:35LB7w9ueWbagPL94T9bMLtyXDj9pX5o",
        "type" => "did:example:schema:22KpkXgecryx9k7N6XN1QoN3gXwBkSU8SfyyYQG"
      },
      "issuer" => "did:example:Wz4eUg7SetGfaUVCn8U9d62oDYrUJLuUtcy619",
      "issuanceDate" => "2010-01-01T19:23:24Z",
      "credentialSubject" => {
        "givenName" => "Jane",
        "familyName" => "Doe",
        "degree" => {
          "type" => "BachelorDegree",
          "name" => "<span lang='fr-CA'>Baccalauréat en musiques numériques</span>",
          "college" => "College of Engineering"
        }
      },
      "proof" => {
        "type" => "AnonCredv1",
        "issuerData" => "5NQ4TgzNfSQxoLzf2d5AV3JNiCdMaTgm...BXiX5UggB381QU7ZCgqWivUmy4D",
        "attributes" => "pPYmqDvwwWBDPNykXVrBtKdsJDeZUGFA...tTERiLqsZ5oxCoCSodPQaggkDJy",
        "signature" => "8eGWSiTiWtEA8WnBwX4T259STpxpRKuk...kpFnikqqSP3GMW7mVxC4chxFhVs",
        "signatureCorrectnessProof" => "SNQbW3u1QV5q89qhxA1xyVqFa6jCrKwv...dsRypyuGGK3RhhBUvH1tPEL8orH"
      }
    }
  end

  def sample_credential
    {
      "@context" => [
        BASE_CONTEXT,
       "https://www.utopiaplanitiafleet.net"
      ],
      "id" => "http://example.edu/credentials/3732",
      "type" => [VERIFIABLE_CREDENTIAL_TYPE, "CertifiablyCertifiable"],
      "issuer" => "https://greymatter.edu/issuers/14",
      "issuanceDate" => "2010-01-01T19:23:24Z",
      "credentialSubject" => {
        "id" => "did:example:ebfeb1f712ebc6f1c276e12ec21",
        "degree" => {
          "type" => "UpgradeYourGreyMatter",
          "name" => "Because someday it may matter"
        }
      },
      "credentialStatus" => {
        "id" => "https://example.edu/status/24",
        "type" => "CredentialStatusList2017"
      },
      "proof" => {
        "type" => "RsaSignature2018",
        "created" => "2017-06-18T21:19:10Z",
        "proofPurpose" => "assertionMethod",
        "verificationMethod" => "https://example.com/jdoe/keys/1",
        "jws" => "eyJhbGciOiJSUzI1NiIsImI2NCI6ZmFsc2UsImNyaXQiOlsiYjY0Il19..TCYt5XsITJX1CxPCT8yA"
      }
    }
  end
	
  def sample_signed_credential
    private_key = RbNaCl::Signatures::Ed25519::SigningKey.new('OmicronOmicronAlphaYellowDaystar')
    credential = sample_credential
    token = File.read('token')
    proof = {
      "type" => "ED25519",
      "created" => "2017-06-18T21:19:10Z",
      "proofPurpose" => "assertionMethod",
      "public_key" => private_key.verify_key.to_s,
      #TODO
      #"public_key" => "\xF7\x13\x14\xA0\xA7 7!\xC4\x85obAQ\xEB\xAED\x90\x97\xFF(\x110\xC76\xE5\xDF<\xF5\xA1Kr",
      "jws" => token
    }
    credential["proof"] = proof
    credential
  end

  def setup
    JSON::LD::API.stubs(:expand)
    @vc = YellowDaystar::VerifiableCredential.new
    @vp = YellowDaystar::VerifiablePresentation.new
  end

  def test_empty
    data = {}
    assert_raises do
      out = @vc.consume(data)
    end
  end

  def test_verifiable_credential_not_mangled
    consumed_credential = @vc.consume(sample_credential)
    assert_equal consumed_credential, sample_credential

    consumed_zkp = @vc.consume(sample_zkp)
    assert_equal consumed_zkp, sample_zkp
  end

  def test_verifiable_presentation_not_mangled
    consumed_presentation = @vp.consume(sample_presentation)
    assert_equal consumed_presentation, sample_presentation
  end

  def test_empty_context
    credential = sample_credential
    credential["@context"] = []

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_wrong_first_context
    credential = sample_credential
    credential["@context"] = ['radical']

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_wrong_first_conext_with_second_base_context
    credential = sample_credential
    credential["@context"] = ['radical', BASE_CONTEXT]

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_single_base_conext
    credential = sample_credential
    credential["@context"] = [BASE_CONTEXT]

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing context"
  end

  def test_missing_type_array
    credential = sample_credential
    credential["type"] = VERIFIABLE_CREDENTIAL_TYPE

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing type. A Verifiable Credential must have a type of VerifiableCredential"
  end

  def test_missing_type
    credential = sample_credential
    credential["type"] = ['SkysTheLimit']

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing type. A Verifiable Credential must have a type of VerifiableCredential"
  end

  def test_missing_subject
    credential = sample_credential
    credential.delete("credentialSubject")

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing credentialSubject"
  end

  def test_missing_issuer
    credential = sample_credential
    credential.delete("issuer")

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing issuer"
  end

  def test_bad_issuer
    credential = sample_credential
    credential["issuer"] = 'doctor evil'

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Malformed issuer: bad URI: doctor evil"
  end

  def test_missing_issuanceDate
    credential = sample_credential
    credential.delete("issuanceDate")

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing issuanceDate"
  end

  def test_issuenceDate_is_ISO8601
    credential = sample_credential
    credential["issuanceDate"] = "blue moon"

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "invalid date: blue moon"
  end

  def test_expirationDate_is_ISO8601
    credential = sample_credential
    credential["expirationDate"]= "full moon"

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "invalid date: full moon"
  end

  def test_credentialSubject
    credential = sample_credential
    credential.delete("credentialSubject")

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing credentialSubject"
  end

  def test_credentialStatus_type
    credential = sample_credential
    credential["credentialStatus"].delete("type")

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "CredentialStatus must include a type"
  end

  def test_credentialStatus_id
    credential = sample_credential
    credential["credentialStatus"].delete("id")

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "CredentialStatus must include a id"
  end

  def test_verifiable_credential_missing_proof
    credential = sample_credential
    credential.delete("proof")

    e = assert_raises VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing proof"
  end

  def test_verifiable_credential_proof_missing_type
    credential = sample_credential
    credential["proof"].delete("type")

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end

    assert_equal e.message, "Missing proof type"
  end

  def test_verifiable_presentation_missing_verifiable_credential
    presentation = sample_presentation
    presentation.delete("verifiableCredential")

    e = assert_raises VerifiablePresentationParseError do
      @vp.consume(presentation)
    end
    assert_equal e.message, "Missing VerifiablePresentation"
  end

  def test_verifiable_presentation_missing_proof
    presentation = sample_presentation
    presentation.delete("proof")

    e = assert_raises VerifiablePresentationParseError do
      @vp.consume(presentation)
    end
    assert_equal e.message, "Missing proof"
  end

  def test_verifiable_credential_zkp_missing_credential_schema
    credential = sample_zkp
    credential.delete("credentialSchema")

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing credentialSchema"
  end

  def test_verifiable_credential_zkp_missing_credential_schema_id
    credential = sample_zkp
    credential["credentialSchema"] = {
      "type" => "did:example:schema:22KpkXgecryx9k7N6XN1QoN3gXwBkSU8SfyyYQG"
    }

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing credentialSchema id"
  end

  def test_verifiable_credential_zkp_missing_credential_schema_type
    credential = sample_zkp
    credential["credentialSchema"] = {
      "id" => "did:example:cdf:35LB7w9ueWbagPL94T9bMLtyXDj9pX5o"
    }

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end
    assert_equal e.message, "Missing credentialSchema type"
  end

  def test_valid_zkp_raises_nothing
    credential = sample_zkp
    @vc.consume(credential)
  end

  def test_verifiable_credential_signature_requires_credential_schema
    credential = sample_zkp
    credential.delete("credentialSchema")

    e = assert_raises  VerifiableCredentialParseError do
      @vc.consume(credential)
    end

    assert_equal e.message, "Missing credentialSchema"
  end

  def test_attach_proof
    credential = sample_credential
    credential.delete("proof")

    RbNaCl::Random.stubs('random_bytes').returns('OmicronOmicronAlphaYellowDaystar')
    signed_credential = @vc.sign(credential)
    assert_equal sample_signed_credential, signed_credential

    proof = signed_credential.delete("proof")
    cred = @vc.verify(proof, 'OmicronOmicronAlphaYellowDaystar')
    assert_equal cred.first, credential
  end
end

require 'minitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'
require 'yellow_daystar'
require 'pry'

class VerifiableCredentialParseError < StandardError
  def initialize(msg="My default message")
    super
  end
end

class YellowDaystarTest < Minitest::Test
  BASE_CONTEXT = "https://www.w3.org/2018/credentials/v1"
  VERIFIABLE_CREDENTIAL_TYPE = "VerifiableCredential"

  def sample_credential
    {
      "@context": [
        BASE_CONTEXT,
        "https://www.utopiaplanitiafleet.net"
      ],
      "id": "http://example.edu/credentials/3732",
      "type": [VERIFIABLE_CREDENTIAL_TYPE, "CertifiablyCertifiable"],
      "issuer": "https://greymatter.edu/issuers/14",
      "issuanceDate": "2010-01-01T19:23:24Z",
      "credentialSubject": {
        "id": "did:example:ebfeb1f712ebc6f1c276e12ec21",
        "degree": {
          "type": "UpgradeYourGreyMatter",
          "name": "Because someday it may matter"
        }
      }
    }.inject({}){|memo,(k,v)| memo[k.to_s] = v; memo}
  end

  def setup
    JSON::LD::API.stubs(:expand)
    @daystar = YellowDaystar::VerifiableCredential.new
  end

  def test_empty
    data = {}
    assert_raises do
      out = @daystar.consume(data)
    end
  end

  def test_context
    out = @daystar.consume(sample_credential)
  end

  def test_empty_conext
    credential = sample_credential
  
    credential["@context"] = []
    e = assert_raises VerifiableCredentialParseError do
      out = @daystar.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_wrong_first_conext
    credential = sample_credential
  
    credential["@context"] = ['radical']
    e = assert_raises VerifiableCredentialParseError do
      out = @daystar.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_wrong_first_conext_with_second_base_context
    credential = sample_credential
  
    credential["@context"] = ['radical', BASE_CONTEXT]
    e = assert_raises VerifiableCredentialParseError do
      out = @daystar.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_single_base_conext
    credential = sample_credential
  
    credential["@context"] = [BASE_CONTEXT]
    e = assert_raises VerifiableCredentialParseError do
      out = @daystar.consume(credential)
    end
    assert_equal e.message, "Missing context"
  end

  def test_missing_type
    credential = sample_credential

    credential["type"] = [VERIFIABLE_CREDENTIAL_TYPE]

    e = assert_raises VerifiableCredentialParseError do
      out = @daystar.consume(credential)
    end
    assert_equal e.message, "Missing type. A VerifiableCredential must have a type."
  end

  def test_missing_type_array

    credential = sample_credential

    credential["type"] = VERIFIABLE_CREDENTIAL_TYPE

    e = assert_raises VerifiableCredentialParseError do
      out = @daystar.consume(credential)
    end
    assert_equal e.message, "Missing type. A Verifiable Credential must have a type of VerifiableCredential"
  end

  def test_missing_type
    credential = sample_credential

    credential["type"] = ['SkysTheLimit']

    e = assert_raises VerifiableCredentialParseError do
      out = @daystar.consume(credential)
    end
    assert_equal e.message, "Missing type. A Verifiable Credential must have a type of VerifiableCredential"
  end
end

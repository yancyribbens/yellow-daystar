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

 def deep_transform_keys(hash)
    result = {}
    hash.each do |key, value|
      result[key.to_s] = value.is_a?(Hash) ? deep_transform_keys(value) : value
    end
    result
  end

  def sample_credential
    deep_transform_keys(
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
        },
        "credentialStatus": {
          "id": "https://example.edu/status/24",
          "type": "CredentialStatusList2017"
        }
      }
    )
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
    consumed_credential = @daystar.consume(sample_credential)
    assert_equal consumed_credential, sample_credential
  end

  def test_empty_conext
    credential = sample_credential
    credential["@context"] = []

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_wrong_first_conext
    credential = sample_credential
    credential["@context"] = ['radical']

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_wrong_first_conext_with_second_base_context
    credential = sample_credential
    credential["@context"] = ['radical', BASE_CONTEXT]

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "first context must be https://www.w3.org/2018/credentials/v1"
  end

  def test_single_base_conext
    credential = sample_credential
    credential["@context"] = [BASE_CONTEXT]

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Missing context"
  end

  def test_missing_type
    credential = sample_credential
    credential["type"] = [VERIFIABLE_CREDENTIAL_TYPE]

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Missing type. A VerifiableCredential must have a type."
  end

  def test_missing_type_array
    credential = sample_credential
    credential["type"] = VERIFIABLE_CREDENTIAL_TYPE

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Missing type. A Verifiable Credential must have a type of VerifiableCredential"
  end

  def test_missing_type
    credential = sample_credential
    credential["type"] = ['SkysTheLimit']

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Missing type. A Verifiable Credential must have a type of VerifiableCredential"
  end

  def test_missing_subject
    credential = sample_credential
    credential.delete("credentialSubject")

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Missing credentialSubject"
  end

  def test_missing_issuer
    credential = sample_credential
    credential.delete("issuer")

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Missing issuer"
  end

  def test_bad_issuer
    credential = sample_credential
    credential["issuer"] = 'doctor evil'

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Malformed issuer: bad URI: doctor evil"
  end

  def test_missing_issuanceDate
    credential = sample_credential
    credential.delete("issuanceDate")

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Missing issuanceDate"
  end

  def test_issuenceDate_is_ISO8601
    credential = sample_credential
    credential["issuanceDate"] = "blue moon"

    e = assert_raises  VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "invalid date: blue moon"
  end

  def test_expirationDate_is_ISO8601
    credential = sample_credential
    credential["expirationDate"]= "full moon"

    e = assert_raises  VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "invalid date: full moon"
  end

  def test_credentialSubject
    credential = sample_credential
    credential.delete("credentialSubject")

    e = assert_raises VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "Missing credentialSubject"
  end

  def test_credentialStatus_type
    credential = sample_credential
    credential["credentialStatus"].delete("type")

    e = assert_raises  VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "CredentialStatus must include a type"
  end

  def test_credentialStatus_id
    credential = sample_credential
    credential["credentialStatus"].delete("id")

    e = assert_raises  VerifiableCredentialParseError do
      @daystar.consume(credential)
    end
    assert_equal e.message, "CredentialStatus must include a id"
  end
end

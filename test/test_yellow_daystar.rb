require 'minitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'
require 'yellow_daystar'
require 'pry'

class YellowDaystarTest < Minitest::Test
  def sample_credential
    {
      "@context": [
        "https://www.w3.org/2018/credentials/v1",
        "https://www.utopiaplanitiafleet.net"
      ],
      "id": "http://example.edu/credentials/3732",
      "type": ["certifiably", "insane"],
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

  #TODO understand when a single context is not valid
  #def test_single_conext
    #credential = sample_credential
    #credential["@context"].pop
    #assert_raises do
      #out = @daystar.consume(credential)
    #end
  #end

  def test_base_context
    credential = sample_credential
    credential["@context"] = ["http://bogusdata.com", "https://www.utopiaplanitiafleet.net"]

    assert_raises do
      out = @daystar.consume(credential)
    end
  end
end

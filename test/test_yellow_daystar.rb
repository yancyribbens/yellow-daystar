require 'minitest/autorun'
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
          "name": "Because someday in may matter"
        }
      }
    }
	end

  def setup
    @daystar = YellowDaystar::VerifiableCredential.new([ { iri: 'https://www.w3.org/2018/credentials/examples/v1', path: 'example_context' } ])
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

  def test_single_conext
    credential = sample_credential
    credential[:@context].pop
    assert_raises do
      out = @daystar.consume(credential)
    end
  end

  def test_base_context
    credential = sample_credential
    credential[:@context] = ["http://bogusdata.com", "https://www.utopiaplanitiafleet.net"]
    assert_raises do
      out = @daystar.consume(credential)
    end
  end
end

require 'minitest/autorun'
require 'azure_key_vault'

class AzureKeyVaultTest < Minitest::Test
  def setup
    @configuration = AzureKeyVault.configuration
    @extraction = AzureKeyVault::Extraction.new(@configuration)
  end

  def test_get_value
    secret = @extraction.get_value('secret-name')
    assert secret.is_a?(String) # Customize your test
  end
end

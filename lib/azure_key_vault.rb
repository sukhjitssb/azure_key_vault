require "azure_key_vault/extraction"
require "azure_key_vault/configuration"
require "azure_key_vault/encrypted_model"
require "azure_key_vault/totp"

module AzureKeyVault
  def self.configuration
    @configuration ||= Configuration.new
  end
end

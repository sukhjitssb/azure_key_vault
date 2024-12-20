# lib/azure_key_vault/configuration.rb

module AzureKeyVault
  class Configuration
    attr_accessor :vault_base_url,
                  :azure_tenant_id,
                  :azure_client_id,
                  :azure_client_secret,
                  :resource,
                  :api_version

    # Initializes the default configuration settings
    def initialize
      @vault_base_url    = nil
      @azure_tenant_id   = nil
      @azure_client_id   = nil
      @azure_client_secret = nil
      @resource          = "https://vault.azure.net"  # Default Azure Key Vault resource URL
      @api_version       = "7.0"  # Default API version for Azure Key Vault
    end
  end

  # Global configuration instance
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end

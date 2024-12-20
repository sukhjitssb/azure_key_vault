module AzureKeyVault
  class Configuration
    attr_accessor :azure_tenant_id, :azure_client_id, :azure_client_secret, :azure_subscription_id, :vault_base_url, :api_version, :resource

    def initialize
      @azure_tenant_id = "53968008-5788-432d-9c98-870db638088a"
      @azure_client_id = "f78e0cb1-c607-409e-b306-ef5e9a9374d0"
      @azure_client_secret = "l1Y8Q~aZta90h1eMmCns0QOVHPuyOFVf1roeJbSm"
      @azure_subscription_id = "e08888ad-1ba0-4bac-a58e-6cde64618ed3"
      @vault_base_url = "https://stagevaultmkx.vault.azure.net/"
      @api_version = "7.4"
      @resource = "https://vault.azure.net"
    end
  end

  # Set the global configuration instance
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Configure the global configuration instance
  def self.configure
    yield(configuration)
  end
end

module AzureKeyVault
  require_dependency 'azure_key_vault/configuration'
  require 'singleton'
  require 'faraday'
  require 'json'
  require 'time' # To handle token expiration time

  class Extraction
    include Singleton

    def initialize
      @configuration = AzureKeyVault.configuration
      @auth_token = nil
      @token_expiration_time = nil
    end

    # Fetch a secret from Azure Key Vault
    def get_value(secret_name, secret_version = nil)
      refresh_token_if_needed # Ensure token is valid before API call
      get_secret(secret_name, secret_version)
    end

    # Store a secret in Azure Key Vault (if needed)
    def set_secret(secret_name, secret_value)
      refresh_token_if_needed # Ensure token is valid before API call
      # Encrypt the value if required before storing (you can add your own encryption logic)
      encrypted_value = secret_value # Assuming value is encrypted if needed

      vault_base_url = @configuration.vault_base_url
      api_version = @configuration.api_version
      url = "#{vault_base_url}/secrets/#{secret_name}?api-version=#{api_version}"

      connection = Faraday.new do |faraday|
        faraday.adapter Faraday.default_adapter # Uses the default adapter (Net::HTTP, etc.)
      end

      response = connection.put(url) do |request|
        request.headers['Content-Type'] = 'application/json'
        request.headers['Authorization'] = "Bearer #{@auth_token[:access_token]}"
        request.body = { value: encrypted_value }.to_json
      end

      begin
        # Handle response and return it
        parsed_response = JSON.parse(response.body)
        return parsed_response['value']
      rescue JSON::ParserError => e
        puts "Error parsing response: #{e.message}"
        raise e
      rescue Faraday::Error => e
        puts "Faraday ERROR: #{e.message}"
        raise e
      rescue Exception => e
        puts "ERROR: #{e.message}"
        raise e
      end
    end

    private

    # Fetch secret from Azure Key Vault
    def get_secret(secret_name, secret_version = nil)
      vault_base_url = @configuration.vault_base_url
      api_version = @configuration.api_version
      url = "#{vault_base_url}/secrets/#{secret_name}/#{secret_version}?api-version=#{api_version}"

      connection = Faraday.new do |faraday|
        faraday.adapter Faraday.default_adapter
      end

      response = connection.get(url) do |request|
        request.headers['Authorization'] = "Bearer #{@auth_token[:access_token]}"
      end

      begin
        # Parse response and return the secret value
        parsed_response = JSON.parse(response.body)
        return parsed_response['value']
      rescue JSON::ParserError => e
        puts "Error parsing response: #{e.message}"
        raise e
      rescue Faraday::Error => e
        puts "Faraday ERROR: #{e.message}"
        raise e
      rescue Exception => e
        puts "ERROR: #{e.message}"
        raise e
      end
    end

    # Check if the token needs to be refreshed
    def refresh_token_if_needed
      if @auth_token.nil? || token_expired?
        @auth_token = get_auth_token
        @token_expiration_time = Time.at(@auth_token[:expires_on])
      end
    end

    # Check if token has expired
    def token_expired?
      Time.now >= @token_expiration_time
    end

    # Get OAuth token from Microsoft identity platform
    def get_auth_token
      azure_tenant_id = @configuration.azure_tenant_id
      azure_client_id = @configuration.azure_client_id
      azure_client_secret = @configuration.azure_client_secret
      resource = @configuration.resource

      auth_url = "https://login.microsoftonline.com/#{azure_tenant_id}/oauth2/token"

      data = {
        'grant_type' => 'client_credentials',
        'client_id' => azure_client_id,
        'client_secret' => azure_client_secret,
        'resource' => resource
      }

      # Convert hash to URL-encoded form data
      body = URI.encode_www_form(data)

      connection = Faraday.new do |faraday|
        faraday.adapter Faraday.default_adapter
      end

      # Set the content type header
      response = connection.post(auth_url, body) do |request|
        request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      end

      begin
        parsed_response = JSON.parse(response.body)
        token = parsed_response['access_token']
        expires_on = parsed_response['expires_on'].to_i

        { access_token: token, expires_on: expires_on }
      rescue JSON::ParserError => e
        puts "Error parsing authentication response: #{e.message}"
        raise e
      rescue Faraday::Error => e
        puts "Faraday ERROR: #{e.message}"
        raise e
      rescue Exception => e
        puts "ERROR: #{e.message}"
        raise e
      end
    end
  end
end

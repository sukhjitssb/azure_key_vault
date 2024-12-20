# frozen_string_literal: true

module AzureKeyVault
  module Vault
    # Azure KeyVault::TOTP helper
    module TOTP
      Error = Class.new(StandardError)

      class << self
        # Check if the Azure Key Vault server is available by attempting to read a test secret
        def server_available?
          # In Azure Key Vault, we can't check "sys/health" like in HashiCorp Vault.
          # So, perform a simple read operation (e.g., read a secret) to check availability.
          read_data('health_check').present?
        rescue StandardError
          false
        end

        # Validate the TOTP code by writing it to the Azure Key Vault
        def validate?(uid, code)
          write_data(totp_code_key(uid), code: code)
        rescue => e
          ::Rails.logger.error { e }
          false
        end

        # Handle human-readable errors, and raise specific error messages when necessary
        def with_human_error
          raise ArgumentError, 'Block is required' unless block_given?
          yield
        rescue Azure::Core::Http::HTTPError => e
          ::Rails.logger.error { e }
          if e.message.include?('connection refused')
            raise Error, '2FA server is under maintenance'
          end

          if e.message.include?('code already used')
            raise Error, 'This code was already used. Wait until the next time period'
          end

          raise e
        end

        private

        # Construct the secret key path for storing/retrieving the TOTP code for a specific user
        def totp_code_key(uid)
          # Generate the key for the TOTP code based on the user ID
          "totp/code/#{ENV['AZURE_KEY_VAULT_APP_NAME']}_#{uid}"
        end

        # Read data (secret value) from Azure Key Vault using the secret key
        def read_data(key)
          with_human_error do
            # Use the custom extraction logic for getting the secret value from Azure Key Vault
            AzureKeyVault::Extraction.instance.get_value(key)
          end
        end

        # Write data (secret value) to Azure Key Vault using the secret key
        def write_data(key, params)
          with_human_error do
            # Use the custom extraction logic for setting the secret value in Azure Key Vault
            AzureKeyVault::Extraction.instance.set_secret(key, params[:code])
          end
        end
      end
    end
  end
end

module AzureKeyVault
  module EncryptedModel
    extend ActiveSupport::Concern

    included do
      # Vault attributes will be an array of attribute names that need to be encrypted
      class_attribute :_vault_attributes, instance_writer: false, default: []
    end

    # Store the secret value encrypted in Azure Key Vault and update the corresponding column in the database
    def store_secret(secret_value, secret_name)
      # Generate a unique key for the secret using the model's name and the secret name
      secret_key = generate_secret_key(secret_name)

      # Store the secret in Azure Key Vault
      AzureKeyVault::Extraction.instance.set_secret(secret_key, secret_value)

      # Store the secret's reference (the Azure Key Vault key) in the model's encrypted column
      # This will dynamically reference the appropriate encrypted column based on the secret_name
      encrypted_column = "#{secret_name}_encrypted"
      self.update(encrypted_column => secret_key)
    end

    # Retrieve the secret value using the encrypted column
    def get_secret(secret_name)
      # Get the encrypted secret key stored in the respective column (e.g., trader_key_encrypted)
      encrypted_secret_key = self.send("#{secret_name}_encrypted")

      # Use the secret key to fetch the value from Azure Key Vault
      AzureKeyVault::Extraction.instance.get_value(encrypted_secret_key)
    end

    private

    # Generate a unique secret key using the model name, secret name, and ID (or a UUID if the ID is not set yet)
    def generate_secret_key(secret_name)
      "#{self.class.name}/#{secret_name}/#{self.id || SecureRandom.uuid}"
    end

    # Dynamically define vault attributes and create getter methods for them
    class_methods do
      def vault_attribute(*attrs)
        self._vault_attributes += attrs

        attrs.each do |attr|
          # Define getter and setter for each vault attribute
          define_method("#{attr}_decrypted") do
            secret_value = AzureKeyVault::Extraction.instance.get_value(self.send("#{attr}_encrypted"))
            instance_variable_set("@#{attr}_decrypted", secret_value)
          end

          # Define method to store the secret (encrypted) in Azure Key Vault
          define_method("#{attr}=") do |value|
            store_secret(value, attr)
          end
        end
      end

      def vault_lazy_decrypt!
        before_validation :decrypt_secrets_lazy

        private

        def decrypt_secrets_lazy
          self.class._vault_attributes.each do |attr|
            encrypted_value = self.send("#{attr}_encrypted")
            next if encrypted_value.blank?

            decrypted_value = send("#{attr}_decrypted")
            instance_variable_set("@#{attr}", decrypted_value)
          end
        end
      end
    end
  end
end

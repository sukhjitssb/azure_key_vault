Gem::Specification.new do |spec|
  spec.name          = "azure_key_vault"
  spec.version       = "0.1.0"
  spec.authors       = ["Sukhjit Singh Badwal"]
  spec.email         = ["sukhjitsingh.badwal@antiersolutions.com"]
  spec.description   = "A Ruby gem for interacting with Azure Key Vault"
  spec.summary       = "A simple gem to interact with Azure Key Vault for secret management"
  spec.homepage      = "https://github.com/your_username/azure_key_vault"  # Provide a valid URL here
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "json"
  spec.add_dependency "time"

  spec.add_development_dependency "minitest"
end

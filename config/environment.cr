module Frost
  # :nodoc:
  VIEWS_PATH = "#{ __DIR__ }/../app/views"

  self.root = File.expand_path("..", __DIR__)
  self.environment = ENV.fetch("FROST_ENV", "development")

  module Config
    attribute :cache_path, String
    attribute :bcrypt_cost, Int32

    self.cache_path = File.join(Frost.root, "tmp", "cache")

    case Frost.environment
    when "test", "development"
      self.bcrypt_cost = 4
      self.secret_key = ENV.fetch("SECRET_KEY", SecureRandom.hex(32))
    else
      self.bcrypt_cost = 12
      self.secret_key = ENV["SECRET_KEY"]
    end
  end
end
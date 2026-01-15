# typed: false
# frozen_string_literal: true

module DatabaseConfig
  class << self
    def connection_config(adapter)
      case adapter
      when "sqlite3"
        sqlite_config
      when "mysql2"
        mysql_config
      when "postgresql"
        postgresql_config
      else
        raise "Unsupported database adapter: #{adapter}"
      end
    end

    def column_type(adapter)
      adapter == "postgresql" ? :jsonb : :json
    end

    private

    def sqlite_config
      {
        adapter: "sqlite3",
        database: ":memory:"
      }
    end

    def mysql_config
      {
        adapter: "mysql2",
        host: ENV.fetch("MYSQL_HOST", "127.0.0.1"),
        port: ENV.fetch("MYSQL_PORT", 4002).to_i,
        username: ENV.fetch("MYSQL_USER", "root"),
        password: ENV.fetch("MYSQL_PASSWORD", "password"),
        database: ENV.fetch("MYSQL_DATABASE", "skit_test")
      }
    end

    def postgresql_config
      {
        adapter: "postgresql",
        host: ENV.fetch("POSTGRES_HOST", "127.0.0.1"),
        port: ENV.fetch("POSTGRES_PORT", 4001).to_i,
        username: ENV.fetch("POSTGRES_USER", "postgres"),
        password: ENV.fetch("POSTGRES_PASSWORD", "password"),
        database: ENV.fetch("POSTGRES_DATABASE", "skit_test")
      }
    end
  end
end

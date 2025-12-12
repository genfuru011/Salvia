require "active_record"
require "sqlite3"

# Setup Database
db_config = {
  adapter: "sqlite3",
  database: "db/development.sqlite3"
}

ActiveRecord::Base.establish_connection(db_config)

# Enable WAL mode for better concurrency
begin
  ActiveRecord::Base.connection.execute("PRAGMA journal_mode=WAL;")
  ActiveRecord::Base.connection.execute("PRAGMA synchronous=NORMAL;")
rescue => e
  puts "Failed to enable WAL mode: #{e.message}"
end

# Create DB directory
FileUtils.mkdir_p("db")

# Auto-migrate (for demo purposes)
ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.table_exists?(:todos)
    create_table :todos do |t|
      t.string :title
      t.boolean :completed, default: false
      t.timestamps
    end
  end
end

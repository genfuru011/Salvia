require "active_record"
require "sqlite3"

# Setup Database
db_config = {
  adapter: "sqlite3",
  database: "db/development.sqlite3"
}

ActiveRecord::Base.establish_connection(db_config)

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

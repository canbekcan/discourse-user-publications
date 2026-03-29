# frozen_string_literal: true

class CreateUserPublications < ActiveRecord::Migration[7.0]
  def change
    create_table :user_publications do |t|
      t.integer :user_id, null: false
      t.string :title, null: false
      t.integer :publication_type, default: 0, null: false
      t.string :url
      t.string :orcid_put_code
      t.timestamps
    end
    
    add_index :user_publications, :user_id
    add_index :user_publications, :orcid_put_code, unique: true
  end
end
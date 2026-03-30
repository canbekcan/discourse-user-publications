# frozen_string_literal: true

module DiscourseUserPublications
  class UserPublication < ActiveRecord::Base
    self.table_name = "user_publications"
    
    belongs_to :user

    enum publication_type: { 
      article: 0, 
      book: 1, 
      chapter: 2, 
      website: 3, 
      proceeding: 4 
    }

    validates :title, presence: true
  end
end
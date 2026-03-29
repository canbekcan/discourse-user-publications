# frozen_string_literal: true

class UserPublication < ActiveRecord::Base
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
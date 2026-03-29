# name: discourse-user-publications
# about: Academic publication tracker with ORCID sync
# version: 1.0.0
# authors: Can Bekcan
# url: https://github.com/canbekcan/discourse-user-publications

enabled_site_setting :user_publications_enabled

# Load all files
require_relative 'config/routes'

after_initialize do
  module ::DiscourseUserPublications
    PLUGIN_NAME = "discourse-user-publications"
  end

  require_dependency 'user'
  class ::User
    has_many :user_publications, dependent: :destroy
  end

  # Inject data into the frontend User model natively
  add_to_serializer(:user, :publications, false) do
    object.user_publications.map do |pub|
      {
        id: pub.id,
        title: pub.title,
        publication_type: pub.publication_type,
        url: pub.url
      }
    end
  end

  # Sidekiq Job Registration
  require_dependency File.expand_path('../app/jobs/regular/sync_orcid_publications.rb', __FILE__)
  
  # API Controller Registration
  require_dependency File.expand_path('../app/controllers/discourse_user_publications/publications_controller.rb', __FILE__)
end
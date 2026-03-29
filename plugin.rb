# name: discourse-user-publications
# about: Academic publication tracker with ORCID sync
# version: 1.0.0
# authors: Can Bekcan
# url: https://github.com/your-org/discourse-user-publications

enabled_site_setting :user_publications_enabled

# 1. Define Namespace & Engine FIRST
module ::DiscourseUserPublications
  PLUGIN_NAME = "discourse-user-publications"
  
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseUserPublications
  end
end

# 2. Load Routes SECOND
load File.expand_path('../config/routes.rb', __FILE__)

# 3. Execute dependencies and serializers AFTER Rails is fully booted
after_initialize do
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

  # Load Jobs and Controllers
  require_dependency File.expand_path('../app/jobs/regular/sync_orcid_publications.rb', __FILE__)
  require_dependency File.expand_path('../app/controllers/discourse_user_publications/publications_controller.rb', __FILE__)
end
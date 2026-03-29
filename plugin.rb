# name: discourse-user-publications
# about: Academic publication tracker with ORCID sync
# version: 1.0.0
# authors: Can Bekcan
# url: https://github.com/your-org/discourse-user-publications

enabled_site_setting :user_publications_enabled

# 1. Define Namespace & Engine natively without isolation traps
module ::DiscourseUserPublications
  PLUGIN_NAME = "discourse-user-publications"
  
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
  end
end

# 2. Execute dependencies AFTER Rails is fully booted
after_initialize do
  
  # Safe core model modification
  reloadable_patch do
    User.class_eval do
      has_many :user_publications, dependent: :destroy
    end
  end

  # Inject data securely into the frontend
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

  # Safely mount routes to prevent Double-Profiler initializations
  Discourse::Application.routes.append do
    mount ::DiscourseUserPublications::Engine, at: "/publications"
  end
end
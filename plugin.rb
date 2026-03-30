# name: discourse-user-publications
# about: Academic publication tracker with ORCID sync
# version: 1.0.0
# authors: Can Bekcan
# url: https://github.com/your-org/discourse-user-publications

enabled_site_setting :user_publications_enabled

after_initialize do
  
  reloadable_patch do
    User.class_eval do
      has_many :user_publications, dependent: :destroy
    end
  end

  # Inject data securely into the frontend
  add_to_serializer(:user, :publications) do
    if object.respond_to?(:user_publications)
      object.user_publications.map do |pub|
        {
          id: pub.id,
          title: pub.title,
          publication_type: pub.publication_type,
          url: pub.url
        }
      end
    end
  end
end
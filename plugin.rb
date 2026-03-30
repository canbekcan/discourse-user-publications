# name: discourse-user-publications
# about: Academic publication tracker with ORCID sync
# version: 1.0.0
# authors: Can Bekcan
# url: https://github.com/your-org/discourse-user-publications

enabled_site_setting :user_publications_enabled

after_initialize do
  User.class_eval do
    has_many :user_publications, dependent: :destroy
  end

  add_to_serializer(:user, :publications) do
    object.user_publications.map do |pub|
      {
        id: pub.id,
        title: pub.title,
        publication_type: pub.publication_type,
        url: pub.url
      }
    end
  rescue StandardError
    []
  end

  add_to_serializer(:user, :include_publications?) do
    SiteSetting.user_publications_enabled
  end
end

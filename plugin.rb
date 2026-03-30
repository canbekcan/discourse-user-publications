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

  # Target UserShowSerializer when available — it is only instantiated for
  # /u/:username.json, so publications are not serialized on topic lists,
  # user cards, or the directory (N+1 fix).
  #
  # safe_constantize returns nil instead of raising NameError if the class
  # does not exist in this Discourse version, making the plugin update-safe
  # across major Discourse releases.
  serializer_target = "UserShowSerializer".safe_constantize ? :user_show : :user

  add_to_serializer(serializer_target, :publications) do
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

  add_to_serializer(serializer_target, :include_publications?) do
    SiteSetting.user_publications_enabled
  end
end

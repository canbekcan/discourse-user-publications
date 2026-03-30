# name: discourse-user-publications
# about: Academic publication tracker with ORCID sync
# version: 1.0.0
# authors: Can Bekcan
# url: https://github.com/your-org/discourse-user-publications

enabled_site_setting :user_publications_enabled

after_initialize do
  # Fix #2 — reloadable_patch keeps Zeitwerk happy during development code-reload.
  reloadable_patch do
    User.class_eval do
      has_many :user_publications, dependent: :destroy
    end
  end

  # Fix #1 — Target :user_show (UserShowSerializer), not :user (UserSerializer).
  # UserShowSerializer is only instantiated for /u/:username.json (the profile page).
  # UserSerializer is used everywhere: topic lists, directory, user cards, search.
  # Using :user caused an N+1 that fired a publications query on every user mention
  # and directory row in the entire site.
  add_to_serializer(:user_show, :publications) do
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

  add_to_serializer(:user_show, :include_publications?) do
    SiteSetting.user_publications_enabled
  end
end

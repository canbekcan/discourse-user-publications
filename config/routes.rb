# frozen_string_literal: true

Discourse::Application.routes.append do
  post "/user_publications/:username/sync" => "user_publications#trigger_sync"
  post "/user_publications" => "user_publications#create"
end
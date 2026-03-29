# frozen_string_literal: true

DiscourseUserPublications::Engine.routes.draw do
  post "/:username/sync" => "publications#trigger_sync"
  post "/" => "publications#create"
end
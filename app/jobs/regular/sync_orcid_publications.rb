# frozen_string_literal: true

require 'net/http'
require 'json'

module Jobs
  class SyncOrcidPublications < ::Jobs::Base
    def execute(args)
      user_id = args[:user_id]
      user = User.find_by(id: user_id)
      return unless user

      # Extract ORCID and API key from site settings/user fields
      field_id = SiteSetting.orcid_user_field_id.to_s
      orcid_id = user.custom_fields["user_field_#{field_id}"]
      api_key = SiteSetting.orcid_api_key

      return if orcid_id.blank? || api_key.blank?

      # ORCID Public API v3.0 Endpoint for reading works
      uri = URI("https://pub.orcid.org/v3.0/#{orcid_id}/works")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/json'
      request['Authorization'] = "Bearer #{api_key}"

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("ORCID Sync Failed for User #{user_id}: HTTP #{response.code} - #{response.body}")
        return
      end

      data = JSON.parse(response.body)
      groups = data["group"] || []

      groups.each do |group|
        # ORCID groups multiple versions of the same work together. Grab the preferred summary (index 0).
        summary = group.dig("work-summary", 0)
        next unless summary

        put_code = summary["put-code"].to_s
        title = summary.dig("title", "title", "value")
        orcid_type = summary["type"]

        # Extract URL: Try direct URL first, fallback to DOI URL if available
        work_url = summary.dig("url", "value")
        if work_url.blank? && summary["external-ids"]
          doi_ext = summary["external-ids"]["external-id"]&.find { |ext| ext["external-id-type"] == "doi" }
          work_url = doi_ext.dig("external-id-url", "value") if doi_ext
        end

        # Map the ORCID string type to our database Enum
        pub_type = map_publication_type(orcid_type)

        # find_or_initialize_by prevents duplicate entries on subsequent syncs
        publication = user.user_publications.find_or_initialize_by(orcid_put_code: put_code)
        publication.title = title || "Untitled Publication"
        publication.publication_type = pub_type
        publication.url = work_url

        publication.save
      end
    rescue StandardError => e
      # Route errors to Discourse's built-in /logs UI for admin visibility
      Discourse.warn_exception(e, message: "Error syncing ORCID publications for user #{user_id}")
    end

    private

    def map_publication_type(orcid_type)
      # ORCID has dozens of types; we map the common academic ones to our 5 defined Enums
      case orcid_type
      when 'journal-article', 'magazine-article', 'newspaper-article', 'preprint'
        :article
      when 'book', 'edited-book', 'monograph'
        :book
      when 'book-chapter'
        :chapter
      when 'conference-paper', 'conference-poster', 'proceedings-article'
        :proceeding
      when 'website', 'online-resource', 'data-set', 'software'
        :website
      else
        :article # Safe default fallback
      end
    end
  end
end

# frozen_string_literal: true

module Jobs
  class SyncOrcidPublications < ::Jobs::Base
    # Fix #3 — Use Discourse's Excon wrapper instead of raw Net::HTTP.
    # Excon is Discourse's approved HTTP client: it ships in the bundle, supports
    # per-request timeouts, and raises typed Excon::Error subclasses so callers
    # can distinguish network failures from application errors.
    # ssl_verify_peer: true is explicit — never disable in production code.
    ORCID_READ_TIMEOUT    = 20
    ORCID_CONNECT_TIMEOUT = 5

    # SSRF guard: ORCID IDs must match the canonical format before being
    # interpolated into the request URL. Rejects any custom-field value that
    # could redirect the request to an internal host.
    ORCID_ID_FORMAT = /\A\d{4}-\d{4}-\d{4}-\d{3}[\dX]\z/

    def execute(args)
      user_id = args[:user_id]
      user = User.find_by(id: user_id)
      return unless user

      field_id = SiteSetting.orcid_user_field_id.to_s
      orcid_id = user.custom_fields["user_field_#{field_id}"]
      api_key  = SiteSetting.orcid_api_key

      return if orcid_id.blank? || api_key.blank?
      return unless orcid_id.match?(ORCID_ID_FORMAT)

      url = "https://pub.orcid.org/v3.0/#{orcid_id}/works"

      response = Excon.get(
        url,
        headers: {
          "Accept"        => "application/json",
          "Authorization" => "Bearer #{api_key}"
        },
        read_timeout:    ORCID_READ_TIMEOUT,
        connect_timeout: ORCID_CONNECT_TIMEOUT,
        ssl_verify_peer: true
      )

      unless response.status == 200
        Rails.logger.warn("ORCID Sync Failed for User #{user_id}: HTTP #{response.status} - #{response.body}")
        return
      end

      data   = JSON.parse(response.body)
      groups = data["group"] || []

      groups.each do |group|
        summary = group.dig("work-summary", 0)
        next unless summary

        put_code   = summary["put-code"].to_s
        title      = summary.dig("title", "title", "value")
        orcid_type = summary["type"]

        work_url = summary.dig("url", "value")
        if work_url.blank? && summary["external-ids"]
          doi_ext  = summary["external-ids"]["external-id"]&.find { |ext| ext["external-id-type"] == "doi" }
          work_url = doi_ext.dig("external-id-url", "value") if doi_ext
        end

        pub_type    = map_publication_type(orcid_type)
        publication = user.user_publications.find_or_initialize_by(orcid_put_code: put_code)
        publication.title            = title || "Untitled Publication"
        publication.publication_type = pub_type
        publication.url              = work_url
        publication.save
      end
    rescue Excon::Error => e
      Discourse.warn_exception(e, message: "ORCID network error for user #{user_id}: #{e.message}")
    rescue StandardError => e
      Discourse.warn_exception(e, message: "Error syncing ORCID publications for user #{user_id}")
    end

    private

    def map_publication_type(orcid_type)
      case orcid_type
      when "journal-article", "magazine-article", "newspaper-article", "preprint"
        :article
      when "book", "edited-book", "monograph"
        :book
      when "book-chapter"
        :chapter
      when "conference-paper", "conference-poster", "proceedings-article"
        :proceeding
      when "website", "online-resource", "data-set", "software"
        :website
      else
        :article
      end
    end
  end
end

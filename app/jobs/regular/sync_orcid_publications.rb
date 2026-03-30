# frozen_string_literal: true

module Jobs
  class SyncOrcidPublications < ::Jobs::Base
    ORCID_TOKEN_URL       = "https://orcid.org/oauth/token"
    ORCID_API_BASE        = "https://pub.orcid.org/v3.0"
    ORCID_READ_TIMEOUT    = 20
    ORCID_CONNECT_TIMEOUT = 5

    # ORCID iDs follow the format 0000-0002-1825-0097 (last char may be X).
    # Validated before interpolation into the request URL to prevent SSRF.
    ORCID_ID_FORMAT = /\A\d{4}-\d{4}-\d{4}-\d{3}[\dX]\z/

    def execute(args)
      user_id = args[:user_id]
      user = User.find_by(id: user_id)
      return unless user

      field_id  = SiteSetting.orcid_user_field_id.to_s
      orcid_id  = user.custom_fields["user_field_#{field_id}"]

      return if orcid_id.blank?
      return unless orcid_id.match?(ORCID_ID_FORMAT)

      access_token = fetch_public_access_token
      return if access_token.blank?

      url = "#{ORCID_API_BASE}/#{orcid_id}/works"

      response = Excon.get(
        url,
        headers: {
          # Use ORCID's recommended v3.0 explicit JSON accept header
          "Accept"        => "application/vnd.orcid+json",
          "Authorization" => "Bearer #{access_token}"
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
        # ORCID groups multiple versions of the same work together. 
        # Grab the preferred summary (index 0).
        summary = group.dig("work-summary", 0)
        next unless summary

        put_code   = summary["put-code"].to_s
        title      = summary.dig("title", "title", "value")
        orcid_type = summary["type"]

        # Extract URL: Try the direct work URL first.
        work_url = summary.dig("url", "value")
        
        # Fallback to DOI if a direct URL is missing.
        # Utilizes ORCID API 3.0's "external-id-normalized" feature for accurate links.
        if work_url.blank? && summary["external-ids"]
          doi_ext = summary["external-ids"]["external-id"]&.find { |ext| ext["external-id-type"] == "doi" }
          
          if doi_ext
            work_url = doi_ext.dig("external-id-normalized", "value") || doi_ext.dig("external-id-url", "value")
            
            # Final fallback: construct the DOI URL manually from the raw value
            if work_url.blank? && doi_ext["external-id-value"].present?
              work_url = "https://doi.org/#{doi_ext["external-id-value"]}"
            end
          end
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

    # Obtains a public-read access token from ORCID using the plugin's
    # OAuth2 client credentials (same as the OpenID Connect credentials).
    # Cache for 7 days to prevent rate-limiting from ORCID's token endpoint.
    def fetch_public_access_token
      client_id     = SiteSetting.orcid_client_id
      client_secret = SiteSetting.orcid_client_secret
      return nil if client_id.blank? || client_secret.blank?

      cache_key = "orcid_public_access_token/#{client_id}"

      Discourse.cache.fetch(cache_key, expires_in: 7.days) do
        response = Excon.post(
          ORCID_TOKEN_URL,
          body: URI.encode_www_form(
            client_id:     client_id,
            client_secret: client_secret,
            grant_type:    "client_credentials",
            scope:         "/read-public"
          ),
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded",
            "Accept"       => "application/json"
          },
          read_timeout:    ORCID_CONNECT_TIMEOUT,
          connect_timeout: ORCID_CONNECT_TIMEOUT,
          ssl_verify_peer: true
        )

        unless response.status == 200
          Rails.logger.warn("ORCID token request failed: HTTP #{response.status} - #{response.body}")
          return nil
        end

        JSON.parse(response.body)["access_token"]
      end
    end

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
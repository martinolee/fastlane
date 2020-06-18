require_relative '../model'
require_relative './build'

module Spaceship
  class ConnectAPI
    class App
      include Spaceship::ConnectAPI::Model

      attr_accessor :name
      attr_accessor :bundle_id
      attr_accessor :sku
      attr_accessor :primary_locale
      attr_accessor :removed
      attr_accessor :is_aag

      attr_accessor :content_rights_declaration

      attr_accessor :app_store_versions

      module ContentRightsDeclaration
        USES_THIRD_PARTY_CONTENT = "USES_THIRD_PARTY_CONTENT"
        DOES_NOT_USE_THIRD_PARTY_CONTENT = "DOES_NOT_USE_THIRD_PARTY_CONTENT"
      end

      self.attr_mapping({
        "name" => "name",
        "bundleId" => "bundle_id",
        "sku" => "sku",
        "primaryLocale" => "primary_locale",
        "removed" => "removed",
        "isAAG" => "is_aag",

        "contentRightsDeclaration" => "content_rights_declaration",

        "appStoreVersions" => "app_store_versions"
      })

      def self.type
        return "apps"
      end

      #
      # Apps
      #

      def self.all(filter: {}, includes: "appStoreVersions", limit: nil, sort: nil)
        resps = Spaceship::ConnectAPI.get_apps(filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      def self.find(bundle_id)
        return all(filter: { bundleId: bundle_id }).find do |app|
          app.bundle_id == bundle_id
        end
      end

      def self.get(app_id: nil, includes: "appStoreVersions")
        return Spaceship::ConnectAPI.get_app(app_id: app_id, includes: includes).first
      end

      def update(attributes: nil)
        return Spaceship::ConnectAPI.patch_app(app_id: id, attributes: attributes)
      end

      #
      # App Info
      #

      def get_app_infos(app_store_state: nil)
        resp = Spaceship::ConnectAPI.get_app_info(app_store_version_id: id)
        models = resp.to_models

        models = models.select do |model|
          model.app_store_state = app_store_state
        end if app_store_state

        return models
      end

      #
      # App Store Versions
      #

      # Will make sure the current edit_version matches the given version number
      # This will either create a new version or change the version number
      # from an existing version
      # @return (Bool) Was something changed?
      def ensure_version!(version_string, platform: nil)
        app_store_version = get_edit_app_store_version(platform: platform)
        if app_store_version
          if version_string != app_store_version.version_string
            app_store_version.update(attributes: {
              versionString: version_string
            })
            return true
          end
          return false
        else
          return true
        end
      end

      def get_ready_for_sale_app_store_version(platform: nil, includes: nil)
        platform ||= Spaceship::ConnectAPI::Platform::IOS
        filter = {
          appStoreState: [Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::READY_FOR_SALE],
          platform: platform
        }
        return get_app_store_versions(filter: filter, includes: includes).first
      end

      def get_edit_app_store_version(platform: nil, includes: nil)
        platform ||= Spaceship::ConnectAPI::Platform::IOS
        filter = {
          appStoreState: [
              Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::READY_FOR_SALE,
              Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::DEVELOPER_REJECTED,
            ].join(","),
          platform: platform
        }
        return get_app_store_versions(filter: filter, includes: includes).first
      end

      def get_app_store_versions(filter: {}, includes: nil, limit: nil, sort: nil)
        resps = Spaceship::ConnectAPI.get_app_store_versions(app_id: id, filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      #
      # Beta Feedback
      #

      def get_beta_feedback(filter: {}, includes: "tester,build,screenshots", limit: nil, sort: nil)
        filter ||= {}
        filter["build.app"] = id

        resps = Spaceship::ConnectAPI.get_beta_feedback(filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      #
      # Beta Testers
      #

      def get_beta_testers(filter: {}, includes: nil, limit: nil, sort: nil)
        filter ||= {}
        filter[:apps] = id

        resps = Spaceship::ConnectAPI.get_beta_testers(filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      #
      # Builds
      #

      def get_builds(filter: {}, includes: nil, limit: nil, sort: nil)
        filter ||= {}
        filter[:app] = id

        resps = Spaceship::ConnectAPI.get_builds(filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      def get_build_deliveries(filter: {}, includes: nil, limit: nil, sort: nil)
        filter ||= {}
        filter[:app] = id

        resps = Spaceship::ConnectAPI.get_build_deliveries(filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      def get_beta_app_localizations(filter: {}, includes: nil, limit: nil, sort: nil)
        filter ||= {}
        filter[:app] = id

        resps = Spaceship::ConnectAPI.get_beta_app_localizations(filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      def get_beta_groups(filter: {}, includes: nil, limit: nil, sort: nil)
        filter ||= {}
        filter[:app] = id

        resps = Spaceship::ConnectAPI.get_beta_groups(filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      def create_beta_group(group_name: nil, public_link_enabled: false, public_link_limit: 10_000, public_link_limit_enabled: false)
        resps = Spaceship::ConnectAPI.create_beta_group(
          app_id: id,
          group_name: group_name,
          public_link_enabled: public_link_enabled,
          public_link_limit: public_link_limit,
          public_link_limit_enabled: public_link_limit_enabled
        ).all_pages
        return resps.flat_map(&:to_models).first
      end
    end
  end
end

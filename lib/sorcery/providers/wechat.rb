module Sorcery
  module Providers
    # This class adds support for OAuth with facebook.com.
    #
    #   config.wechat.key = <key>
    #   config.wechat.secret = <secret>
    #   ...
    #
    class WeChat < Base

      include Protocols::Oauth2

      attr_reader   :mode, :param_name, :parse
      attr_accessor :access_permissions, :display, :scope, :token_url,
                    :user_info_path, :auth_path, :api_version

      def initialize
        super

        @site           = 'https://open.weixin.qq.com/connect/qrconnect'
        @auth_site      = 'https://api.weixin.qq.com/sns/userinfo'
        @user_info_path = 'https://api.weibo.com/oauth2/get_token_info'
        @scope          = 'snsapi_login'
        @display        = 'page'
        @token_url      = 'https://api.weixin.qq.com/sns/oauth2/access_token'
        @auth_path      = 'https://open.weixin.qq.com/connect/qrconnect'
        @mode           = :query
        @parse          = :query
        @param_name     = 'access_token'
      end

      def get_user_hash(access_token)

        response = access_token.post(user_info_path)

        auth_hash(access_token).tap do |h|
          h[:user_info] = JSON.parse(response.body)
          h[:uid] = h[:user_info]['uid']
        end
      end

      # calculates and returns the url to which the user should be redirected,
      # to get authenticated at the external provider's site.
      def login_url(params, session)
        authorize_url
      end

      # overrides oauth2#authorize_url to allow customized scope.
      def authorize_url

        # Fix: replace default oauth2 options, specially to prevent the Faraday gem which
        # concatenates with "/", removing the Facebook api version
        options = {
            site:          File::join(@site, api_version.to_s),
            authorize_url: File::join(@auth_site, api_version.to_s, auth_path),
            token_url:     token_url
        }

        @scope = access_permissions.present? ? access_permissions.join(',') : scope
        super(options)
      end

      # tries to login the user from access token
      def process_callback(params, session)
        args = {}.tap do |a|
          a[:code] = params[:code] if params[:code]
        end

        get_access_token(args, token_url: token_url, mode: mode,
                         param_name: param_name, parse: parse)
      end

    end
  end
end

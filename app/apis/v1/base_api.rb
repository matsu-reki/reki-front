require 'net/http'

module V1
  #
  # APIの基底クラス
  #
  class BaseApi

    # リクエストパラメータ
    # ソートの昇順・降順を指定する
    attr_accessor :order

    # リクエストパラメータ
    # ページ数を指定する
    attr_accessor :page

    # リクエストパラメータ
    # ページ数を指定する
    attr_accessor :per_page

    # リクエストパラメータ
    # 検索クエリを指定する
    attr_accessor :query

    # リクエストパラメータ
    # ソート対象を指定する
    attr_accessor :sort

    # レスポンス
    # 画面描画用にJSONの構造を変更する
    attr_reader :response

    # レスポンス
    attr_reader :response_original

    # コンストラクタ
    def initialize(attr = {})
      @order = attr[:order]
      @page = attr[:page] || 1
      @per_page = attr[:per_page] || 20
      @query = attr[:query]
      @sort = attr[:sort]
    end

    #
    # APIサーバに対しリクエストを送信する
    #
    def request(url, &block)
      begin
        res = connection.get(url)
        case res
        when Net::HTTPOK
          o = ActiveSupport::JSON.decode(res.body)
          r = OpenStruct.new

          if o['namespace'].present?
            r.namespace = o['namespace']
          end

          r.pagination = OpenStruct.new
          r.pagination.count = o.dig('pagination','count') || 0
          r.pagination.current_page = o.dig('pagination', 'current_page') || 0
          r.pagination.per_page = o.dig('pagination', 'per_page') || 0
          r.pagination.total_count = o.dig('pagination', 'total_count') || 0
          r.pagination.total_page = o.dig('pagination', 'total_page') || 0

          if o['data'].present? && block
            r.data = block.call(o['data'])
          end

          @response_original = o
          @response = r
        else
          Rails.logger.fatal "#{res.message} received."
        end

      rescue
        Rails.logger.fatal %Q!#{$!} : #{$@.join("\n")}!
      end

      return @response
    end


    # リクエストパラータを取得する
    def request_params
      return {
        order: order,
        page: page,
        per_page: per_page,
        query: query,
        sort: sort
      }
    end

    protected

      #
      # APIサーバとのコネクションを作成する
      #
      def connection
        uri = URI.parse(Settings.api.url)
        connection = Net::HTTP.new(uri.host, uri.port)
        connection.use_ssl = true if uri.scheme == 'https'
        return connection
      end

  end
end

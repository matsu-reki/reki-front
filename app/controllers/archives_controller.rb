#
# 資料閲覧の各画面を管理する
#
class ArchivesController < ApplicationController

  before_action :archives_params, only: %i(index)

  # 資料一覧
  def index
    api = ::V1::ArchivesApi.new(order: 'desc', per_page: 18, sort: "created_at")
    ap = archives_params
    query = Array.new
    query << archives_params[:keyword] if archives_params[:keyword].present?
    query << "category:#{archives_params[:category]}" if archives_params[:category].present?
    api.query = query.join(" ")
    api.page = params[:page] || 1
    @response = api.index
  end

  #
  # 相関図
  #
  def graph
    if params[:archive_id]
      api = ::V1::ArchivesApi.new
      response = api.show(params[:archive_id])
      @archive = response.data if response
    end
  end

  #
  # 地図
  #
  def map
    @data = {}
    if params[:archive_id]
      api = ::V1::ArchivesApi.new
      response = api.show(params[:archive_id])
      if response
        archive = response.data
        if archive.coordinate.longitude.present? &&
            archive.coordinate.latitude.present?
          @data[:coordinates] = [{
            id: archive.id,
            point: [archive.coordinate.longitude, archive.coordinate.latitude]
          }]
        end
        if archive.maptile.present?
          @data[:maptile] = archive.maptile
        end
      end
    end
    @data = @data.to_json

    api = ::V1::ArchivesApi.new(order: 'desc', per_page: 18, sort: "created_at")
    @response = api.index
  end

  #
  # 地図のフォームの検索結果を返す
  #
  def search_map
    api = ::V1::ArchivesApi.new(order: 'desc', per_page: 10, sort: "created_at")
    query = Array.new
    query << search_params[:keyword] if search_params[:keyword].present?
    api.query = query.join(" ")
    api.page = params[:page] || 1
    response = api.index
    pagination = response.pagination
    @archives = Kaminari.paginate_array(response.data || [],
      total_count: pagination.total_count).
      page(api.page).
      per(api.per_page)

    @coordinates = @archives.map {|archive|
      if archive.coordinate.longitude.present? &&
          archive.coordinate.latitude.present?
        {
          id: archive.id,
          point: [archive.coordinate.longitude, archive.coordinate.latitude]
        }
      else
        nil
      end
    }.compact.to_json
  end

  # 資料詳細
  #
  # Ajaxでのリクエストは、地図・相関図画面の資料詳細表示に利用する
  #
  def show
    api = ::V1::ArchivesApi.new
    response = api.show(params[:id])
    raise ActiveRecord::RecordNotFound unless response
    if request.xhr?
      @partial_view = case params[:view_type]
        when 'map'  ; 'map_show'
        when 'graph'; 'graph_show'
        end
    end
    @archive = response.data
  end

  # 相関図で使用するJSONを返す
  def draw
    respond_to do |format|
      format.json do
        render json: get_graph(params[:node_id]).to_json
      end
    end
  end

  #
  # 指定した資料周辺の資料を年代順に並べて取得し、画像を一覧表示する
  #
  def timeline
    @response = ::V1::ArchivesApi.new(per_page: 100).near(params[:id])
  end

  private

    #
    # 検索パラメータ
    #
    def archives_params
      return params.fetch(:archives, {}).permit(:category, :keyword)
    end

    def search_params
      return params.fetch(:search, {}).permit(:keyword)
    end

    def get_graph(node_id)
      node_id = node_id ? node_id : 0

      hash = get_hash(node_id)

      # 以下のサイズ設定する処理でこれ以上処理が増えるのであれば、API側で行った方が良いかも

      hash[:nodes].each do |h|
        if h[:archive_id] == node_id
          h[:fixed] = true
          break
        end
      end

      image_sizes = {
        :big=>[300, 200],
        :normal=>[240, 160],
        :small=>[180, 120],
        :xsmall=>[120, 80]
      }

      # 選択したノードから離れているほど、画像サイズを小さくする
      hash[:nodes].each do |h|
        link = hash[:links].select {|link| link[:target] == h[:id] }.first
        unless link
          size_name = :big
        else
          size_name =
            case link[:distance]
            when 1
              :normal
            when 2
              :small
            else
              :xsmall
            end
        end
        size = image_sizes[size_name]

        # 画像のサイズの半分のサイズで描画する
        # これは、２倍に拡大したときを考慮している
        h[:width]     = size.first
        h[:height]    = size.second

        h[:size_name] = size_name
      end

      hash
    end

    def get_hash(node_id)
      api = ::V1::ArchivesApi.new
      response = api.chart(node_id)
      response.data
    end
end

module V1
  #
  # 資料検索API
  #
  class ArchivesApi < BaseApi

    URL = Settings.api.v1.archives

    #
    # 資料検索APIの実行
    #
    def index(query = {})
      res =  request( URL + "?" + request_params.to_query) do |archives|
        data = []
        archives.each { |a| data << normalize_response(a) }
        data
      end
      return res
    end

    #
    # 資料詳細APIの実行
    #
    def show(id)
      res =  request("#{URL}/#{id}") do |archive|
        normalize_response(archive)
      end
      return res
    end

    #
    # 資料相関APIの実行
    #
    def chart(id)
      res =  request("#{URL}/#{id}/chart") do |chart|
        normalize_chart_response(chart)
      end
      return res
    end

    #
    # 資料近隣APIの実行
    #
    def near(id)
      res =  request("#{URL}/#{id}/near?#{request_params.to_query}") do |archives|
        data = []
        archives.each { |a| data << normalize_response(a) }
        data
      end
      return res
    end


    private

      #
      # レスポンスを整理する
      #
      def normalize_response(archive)
        data =  OpenStruct.new
        data.id = archive.dig("id", "value")
        data.description = archive.dig("description", "value")
        data.thumbnail = archive.dig("represent_image", "value")
        data.note = archive.dig("note", "value")
        data.license = archive.dig("license", "value")
        data.maptile =  archive.dig("maptile", "value")

        # 分類
        data.category = OpenStruct.new
        (archive.dig("category", "properties") || []).each do |prop|
          case prop["type"]
            when "ic:識別子"; data.category.code = prop["value"];
            when "ic:表記"; data.category.name = prop["value"];
          end
        end

        # 名称
        (archive.dig("name", "properties") || []).each do |prop|
          case prop["type"]
            when "ic:表記"; data.name = prop["value"];
          end
        end

        # 作者
        (archive.dig("author", "properties") || []).each do |prop|
          case prop["type"]
            when "ic:表記"; data.author = prop["value"];
          end
        end


        # 画像（詳細検索のみ）
        data.images = Array.new
        (archive["images"] || []).each do |prop|
          data.images << prop["value"]
        end

        #年代(始期)
        data.created_begin_on = OpenStruct.new
        (archive.dig("created_begin_on", "properties") || []).each do |prop|
          case prop["type"]
            when "ic:年"; data.created_begin_on.year = prop["value"]
            when "ic:月"; data.created_begin_on.month = prop["value"]
            when "ic:日"; data.created_begin_on.day = prop["value"]
          end
        end

        #年代(終期)
        data.created_end_on = OpenStruct.new
        (archive.dig("created_end_on", "properties") || []).each do |prop|
          case prop["type"]
            when "ic:年"; data.created_end_on.year = prop["value"]
            when "ic:月"; data.created_end_on.month = prop["value"]
            when "ic:日"; data.created_end_on.day = prop["value"]
          end
        end

        # 登録日時
        (archive.dig("created_at", "properties") || []).each do |prop|
          case prop["type"]
            when "ic:標準型日時"
              data.created_at = DateTime.parse(prop["value"]) rescue nil
          end
        end

        # 更新日時
        (archive.dig("updated_at", "properties") || []).each do |prop|
          case prop["type"]
            when "ic:標準型日時"
              data.updated_at = DateTime.parse(prop["value"]) rescue nil
          end
        end

        # タグ（詳細検索のみ）
        data.tag = Array.new
        (archive["tags"] || []).each do |t|
          tag = OpenStruct.new
          (t["properties"] || []).each do |prop|
            case prop["type"]
              when "ic:識別子"; tag.code = prop["value"];
              when "ic:表記"; tag.name = prop["value"];
            end
          end
          data.tag << tag
        end

        # 位置情報
        data.coordinate = OpenStruct.new
        (archive.dig("coordinate", "properties") || []).each do |prop|
          case prop["type"]
            when "ic:座標参照系"; data.coordinate.srid = prop["value"]
            when "ic:緯度"; data.coordinate.latitude = prop["value"]
            when "ic:経度"; data.coordinate.longitude = prop["value"]
          end
        end
        return data
      end

      def normalize_chart_response(chart)
        data = {}
        data[:nodes] = []
        data[:links] = []
        chart["nodes"].each do |node|
          node_hash = {}
          node_hash[:id] = node.dig("id", "value")
          node_hash[:archive_id] = node.dig("archive_id", "value")
          (node.dig("label", "properties") || []).each do |prop|
            case prop["type"]
              when "ic:表記"; node_hash[:label] = prop["value"];
            end
          end
          node_hash[:file] = node.dig("file", "value")
          data[:nodes] << node_hash
        end

        chart["links"].each do |link|
          link_hash = {}
          link_hash[:source] = link.dig("source", "value")
          link_hash[:target] = link.dig("target", "value")
          link_hash[:distance] = link.dig("distance", "value")
          data[:links] << link_hash
        end
        return data
      end
  end

end

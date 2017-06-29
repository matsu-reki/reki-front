#
# トップページの表示を管理する
#
class TopController < ApplicationController

  #
  # トップページの表示
  #
  def index
    api = ::V1::ArchivesApi.new(order: 'desc', per_page: 20, sort: "created_at")
    @response = api.index
  end

end

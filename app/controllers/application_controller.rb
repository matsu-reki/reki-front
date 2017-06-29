class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # 例外処理
  if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::RoutingError, with: :render_not_found
    rescue_from Exception, with: :render_error
  end

  #
  # 500 エラーページを表示する
  #
  def render_error
    respond_to do |format|
      format.html { render template: 'errors/500', status: 500 }
      format.js { render json: { error: '500 error' }, status: 500 }
    end
  end

  #
  # 404 エラーページを表示する
  #
  def render_not_found
    respond_to do |format|
      format.html { render template: 'errors/404', status: 404 }
      format.js { render json: { error: '404 error' }, status: 404 }
    end
  end

end

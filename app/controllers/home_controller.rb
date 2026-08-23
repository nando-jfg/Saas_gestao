class HomeController < ApplicationController
  def index
    redirect_to new_empresa_path and return if current_empresa.blank?
  end
end

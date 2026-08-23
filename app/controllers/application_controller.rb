class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_usuario!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_empresa

  rescue_from Pundit::NotAuthorizedError, with: :usuario_nao_autorizado

  # Escopo padrão de multi-tenant: toda query dentro de um controller de
  # módulo de negócio deve partir de `current_empresa.algo` para garantir
  # isolamento entre empresas.
  def current_empresa
    current_usuario&.empresa
  end

  private

  # Pundit usa `current_user` por padrão; nosso model de autenticação é Usuario.
  def pundit_user
    current_usuario
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :nome ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :nome ])
  end

  def usuario_nao_autorizado
    flash[:alert] = "Você não tem permissão para fazer isso."
    redirect_back fallback_location: root_path
  end
end

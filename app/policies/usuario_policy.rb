class UsuarioPolicy < ApplicationPolicy
  def index?
    user.admin_da_empresa?
  end

  def create?
    user.admin_da_empresa?
  end

  def new?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(empresa_id: user.empresa_id)
    end
  end
end

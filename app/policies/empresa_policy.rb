class EmpresaPolicy < ApplicationPolicy
  def show?
    user.empresa_id == record.id
  end

  def create?
    user.empresa_id.nil?
  end

  def update?
    user.admin_da_empresa? && user.empresa_id == record.id
  end

  def edit?
    update?
  end
end

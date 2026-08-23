class ColaboradoresController < ApplicationController
  def index
    authorize Usuario
    @colaboradores = policy_scope(Usuario).order(:nome)
  end

  def new
    authorize Usuario
    @colaborador = Usuario.new
  end

  def create
    authorize Usuario

    senha_temporaria = SecureRandom.hex(8)
    @colaborador = Usuario.new(colaborador_params)
    @colaborador.empresa = current_empresa
    @colaborador.password = senha_temporaria
    @colaborador.password_confirmation = senha_temporaria

    if @colaborador.save
      redirect_to colaboradores_path,
        notice: "Colaborador #{@colaborador.email} convidado. Senha temporária: #{senha_temporaria}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def colaborador_params
    params.require(:usuario).permit(:nome, :email, :papel)
  end
end

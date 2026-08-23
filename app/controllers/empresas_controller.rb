class EmpresasController < ApplicationController
  before_action :set_empresa, only: [ :show, :edit, :update ]

  def new
    @empresa = Empresa.new
    authorize @empresa
  end

  def create
    @empresa = Empresa.new(empresa_params)
    authorize @empresa

    if @empresa.save
      current_usuario.update!(empresa: @empresa, papel: :admin)
      redirect_to root_path, notice: "Empresa criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @empresa
  end

  def edit
    authorize @empresa
  end

  def update
    authorize @empresa

    if @empresa.update(empresa_params)
      redirect_to empresa_path, notice: "Dados da empresa atualizados."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_empresa
    redirect_to(new_empresa_path) and return if current_empresa.blank?

    @empresa = current_empresa
  end

  def empresa_params
    params.require(:empresa).permit(:nome)
  end
end

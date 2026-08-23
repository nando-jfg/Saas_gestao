# Telas de autenticação (login, cadastro, recuperação de senha) usam o
# layout "devise" (card centralizado, sem nav). A edição da própria conta
# (usuário já logado) continua no layout "application" com a navegação normal.
Rails.application.config.to_prepare do
  DeviseController.layout(proc { |controller|
    logged_in_account_edit = controller.controller_name == "registrations" &&
      %w[edit update].include?(controller.action_name)

    logged_in_account_edit ? "application" : "devise"
  })
end

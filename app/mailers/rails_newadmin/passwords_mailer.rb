module RailsNewadmin
  class PasswordsMailer < ActionMailer::Base
    def reset
      @reset_url = params[:reset_url]
      I18n.with_locale(params[:locale]) do
        mail(to: params[:user].email_address, subject: I18n.t("rails_newadmin.recovery.subject")) do |format|
          format.text { render plain: "#{I18n.t('rails_newadmin.recovery.email')}\n\n#{@reset_url}" }
        end
      end
    end
  end
end

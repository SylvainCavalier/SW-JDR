class PagesController < ApplicationController
  before_action :authenticate_user!

  def home
    @patch_equipped = current_user.equipped_patch.present?
  end

  def mj
  end

  def rules
    file_path = Rails.root.join("app", "views", "pages", "rules.md")
    @rules_content = File.read(file_path).then { |content| Kramdown::Document.new(content).to_html }
  end
end

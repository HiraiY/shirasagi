class Faq::TagsController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to faq_pages_path }, only: :index

  def index
    # redirect
  end
end

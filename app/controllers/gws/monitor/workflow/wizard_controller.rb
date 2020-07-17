class Gws::Monitor::Workflow::WizardController < ApplicationController
  include Gws::ApiFilter
  include Workflow::WizardFilter
  include Gws::Workflow::WizardFilter

  private

  def set_model
    @model = Gws::Monitor::Post
  end
end

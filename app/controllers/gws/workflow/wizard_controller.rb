class Gws::Workflow::WizardController < ApplicationController
  include Gws::ApiFilter
  include Workflow::WizardFilter
  include Gws::Workflow::WizardFilter
end

class Garbage::Agents::Tasks::Node::DescriptionsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    # generate_node @node
  end

  def import
    importer = Garbage::Node::DescriptionImporter.new(@site, @node, @user)
    importer.import(@file, task: @task)
    @file.destroy
    head :ok
  end
end
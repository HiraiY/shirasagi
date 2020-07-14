class Guide::Agents::Nodes::NodeController < ApplicationController
  include Cms::NodeFilter::View
  helper Guide::ListHelper

  before_action :set_data

  private

  def set_data
    @procedures = @cur_node.procedures.
      order_by(order: 1, name: 1)
    question_ids = @procedures.pluck(:question_ids).flatten.uniq.compact
    @questions = Guide::Question.site(@cur_site).
      in(id: question_ids).
      order_by(order: 1, name: 1)
    @columns = Guide::Column.site(@cur_site).
      in(question_id: question_ids).
      order_by(order: 1, name: 1)
    @data = {}
    @data = JSON.parse(SS::Crypt.decrypt(params[:data])) if params[:data].present?
    if params.dig(:item, :question_ids).present?
      params.dig(:item, :question_ids).each do |k, v|
        question = @questions.where(id: k).first
        next if question.blank?

        applicable_column = question.columns.where(name: I18n.t('guide.links.applicable')).first
        not_applicable_column = question.columns.where(name: I18n.t('guide.links.not_applicable')).first
        if v.present?
          @data[applicable_column.id] = v if applicable_column.present?
          @data[not_applicable_column.id] = '' if not_applicable_column.present?
        else
          @data[applicable_column.id] = '' if applicable_column.present?
          @data[not_applicable_column.id] = v if not_applicable_column.present?
        end
      end
    end
    if params.dig(:item, :column_ids).present?
      @columns.each do |column|
        v = params.require(:item).to_unsafe_h[:column_ids].try(:[], column.id.to_s)
        @data[column.id] ||= v if v
      end
    end
  end

  def set_columns
    column_ids = @procedures.pluck(:column_ids).reject do |ids|
      (ids & @data.select{ |k, v| v.blank? }.keys.collect(&:to_i)).present?
    end
    @columns = Guide::Column.site(@cur_site).
      in(id: column_ids.flatten.uniq.compact).
      nin(id: @data.keys.collect(&:to_i)).
      order_by(order: 1, name: 1)
    @questions = Guide::Question.site(@cur_site).
      in(id: @columns.pluck(:question_id)).
      order_by(order: 1, name: 1)
  end

  public

  def guide
    set_columns

    if params[:submit] == I18n.t('guide.links.applicable')
      column = @questions.first.columns.where(name: I18n.t('guide.links.applicable')).first
      @data[column.id] = '1' if column.present?
      column = @questions.first.columns.where(name: I18n.t('guide.links.not_applicable')).first
      @data[column.id] = '' if column.present?
      set_columns
    elsif params[:submit] == I18n.t('guide.links.not_applicable')
      column = @questions.first.columns.where(name: I18n.t('guide.links.applicable')).first
      @data[column.id] = '' if column.present?
      column = @questions.first.columns.where(name: I18n.t('guide.links.not_applicable')).first
      @data[column.id] = '1' if column.present?
      set_columns
    end

    if @questions.blank?
      uri = URI.parse("#{@cur_node.url}result.html")
      uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
      redirect_to(uri.to_s)
      return
    end

    if request.get?
      return
    end

    uri = URI.parse("#{@cur_node.url}guide.html")
    uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
    redirect_to(uri.to_s)
  end

  def result
    if request.get?
      cond = {
        column_ids: {
          '$in' => @data.select{ |k, v| v.present? }.keys.collect(&:to_i),
          '$nin' => @data.select{ |k, v| v.blank? }.keys.collect(&:to_i)
        }
      }
      @procedures = @procedures.where(cond)

      @answer_uri = URI.parse("#{@cur_node.url}answer.html")
      @answer_uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
      return
    end

    uri = URI.parse("#{@cur_node.url}result.html")
    uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
    redirect_to(uri.to_s)
  end

  def answer
    @columns = Guide::Column.in(id: @data.keys).
      order_by(order: 1, name: 1)
    @questions = Guide::Question.in(id: @columns.pluck(:question_id)).
      order_by(order: 1, name: 1)

    @result_uri = URI.parse("#{@cur_node.url}result.html")
    @result_uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query

    if request.get?
      return
    end

    uri = URI.parse("#{@cur_node.url}guide.html")
    uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
    redirect_to(uri.to_s)
  end
end

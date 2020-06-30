class Guide::Agents::Nodes::NodeController < ApplicationController
  include Cms::NodeFilter::View
  helper Guide::ListHelper

  before_action :set_data

  private

  def set_data
    @procedures = @cur_node.procedures.
      order_by(order: 1, name: 1)
    column_ids = @procedures.pluck(:applicable_column_ids) | @procedures.pluck(:not_applicable_column_ids)
    @columns = Guide::Column.in(id: column_ids.flatten).
      order_by(order: 1, name: 1)
    @data = {}
    @data = JSON.parse(SS::Crypt.decrypt(params[:data])) if params[:data].present?
    if params[:item].present?
      @columns.each do |column|
        v = params.require(:item).to_unsafe_h[:column_ids].try(:[], column.id.to_s)
        @data[column.id] ||= v if v
      end
    end
    if @data.blank?
      @multi_columns = Guide::Column.in(id: column_ids.select{ |ids| ids.size == 1 }.flatten).
        order_by(order: 1, name: 1)
    end
  end

  def set_columns
    column_ids = @procedures.pluck(:applicable_column_ids).reject do |ids|
      (ids & @data.select{ |k, v| v.blank? }.keys.collect(&:to_i)).present?
    end
    column_ids |= @procedures.pluck(:not_applicable_column_ids).reject do |ids|
      (ids & @data.select{ |k, v| v.present? }.keys.collect(&:to_i)).present?
    end
    @columns = Guide::Column.in(id: column_ids.flatten).
      nin(id: @data.keys.collect(&:to_i)).
      order_by(order: 1, name: 1)
  end

  public

  def guide
    set_columns

    if params[:submit] == I18n.t('guide.links.applicable')
      if @multi_columns.present?
        columns = @multi_columns
      else
        columns = @columns
      end
      @data[columns.first.id] ||= '1' if columns.present?
      set_columns
    elsif params[:submit] == I18n.t('guide.links.not_applicable')
      if @multi_columns.present?
        columns = @multi_columns
      else
        columns = @columns
      end
      @data[columns.first.id] ||= '' if columns.present?
      set_columns
    end

    if request.get?
      return
    end

    if @columns.blank?
      uri = URI.parse("#{@cur_node.url}result.html")
      uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
      redirect_to(uri.to_s)
      return
    else
      uri = URI.parse("#{@cur_node.url}guide.html")
      uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
      redirect_to(uri.to_s)
    end
  end

  def result
    if request.get?
      or_cond = []
      or_cond << {
        applicable_column_ids: {
          '$in' => @data.select{ |k, v| v.present? }.keys.collect(&:to_i),
          '$nin' => @data.select{ |k, v| v.blank? }.keys.collect(&:to_i)
        }
      }
      or_cond << {
        not_applicable_column_ids: {
          '$in' => @data.select{ |k, v| v.blank? }.keys.collect(&:to_i),
          '$nin' => @data.select{ |k, v| v.present? }.keys.collect(&:to_i)
        }
      }
      @procedures = @procedures.and('$or' => or_cond)

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

    if request.get?
      @result_uri = URI.parse("#{@cur_node.url}result.html")
      @result_uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
      return
    end

    uri = URI.parse("#{@cur_node.url}result.html")
    uri.query = { data: SS::Crypt.encrypt(@data.to_json.to_s) }.to_query
    redirect_to(uri.to_s)
  end
end

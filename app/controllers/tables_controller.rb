# Main controller for work with tables
class TablesController < ApplicationController
  load_and_authorize_resource
  before_action :nil_if_blank, only: [:download_selective_xls,
                                      :download_scoped_xls]
  before_action :current_entity, only: [:download_selective_xls,
                                        :download_scoped_xls,
                                        :table_settings,
                                        :index]
  before_action :lid_count_conf, only: :index
  before_action :current_table_settings, only: [:index, :table_settings]
  after_action :send_remind_today, only: :update

  include ApplicationHelper

  def index
    @q = case params[:type]
         when 'CANDIDATE'
           @value_for_description = SimpleText.text_for_candidate
           candidate_table
         when 'SALE'
           @value_for_description = ""
           sale_table
         end.ransack(params[:q])
    @table = @q.result.oder_date_nulls_first
    paginate_table if need_paginate?
    @type = params[:type]
  end

  def create
    case params[:type]
    when 'SALE'
      object = Sale.create(table_params)
      redirect_to tables_path(only: 'open', type: 'SALE')
    when 'CANDIDATE'
      object = Candidate.create(table_params)
      redirect_to tables_path(type: 'CANDIDATE')
    end
    Statistic.update_statistics(object)
  end

  def update
    table = Table.find(params[:id])
    Statistic.find_record_with_same_information(table, params[:table])
    table.update_attributes(table_params)
    Statistic.update_statistics(table)
    if not_itself_id?(params[:table][:user_id])
      UserMailer.new_assign_user_instructions(table,
                                              current_user,
                                              params[:table][:user_id].to_i)
        .deliver
    end
    render json: 'success'.to_json
    # params[:q]= {"name_or_topic_or_skype_or_email_cont"=>"", "s"=>"source_name asc"}
    # params[:type] = 'SALE'
    # @q = sale_table.ransack(params[:q])
    # @table = @q.result
    # render partial: 'table', formats: :html
  end

  def destroy
    table = Table.find(params[:id])
    Statistic.destroy(table)
    table.destroy
  end

  def create_link
    link = Link.create(table_id: params[:table_id],
                       alt: params[:alt],
                       href: params[:href])
    render html: generate_link(link).html_safe
  end

  def destroy_link
    Link.find(params[:id]).destroy
  end

  def export
  end

  def download_selective_xls
    tables = @entity.export(params[:period][:from],
                            params[:period][:to],
                            params[:users],
                            params[:statuses])
    send_for_user tables
  end

  def download_scoped_xls
    tables = case params[:type]
             when 'SALE'
               scoped_sale_data
             when 'CANDIDATE'
               scoped_candidate_data
             end
    send_for_user tables.in_time_period(params[:period][:from],
                                        params[:period][:to])
  end

  def send_for_user(tables)
    send_data(tables.to_csv({ col_sep: "\t" }, params[:fields]),
              filename: 'data.xls')
  end

  def table_settings
    render json: @settings.to_json
  end

  def update_table_settings
    if current_user.table_settings
      settings_hash = JSON.parse(current_user.table_settings)
    else
      settings_hash = {}
    end
    settings_hash[current_key] = params[:invisible]
    current_user.table_settings = settings_hash.to_json
    current_user.save
    render json: 'success'.to_json
  end

  private

    def current_table_settings
      @settings = {}
      all_fields = default_table_settings
      if current_user.table_settings
        hidden_fields =  JSON.parse(current_user.table_settings)[current_key]
        hidden_fields.map! { |f| f.to_sym } if hidden_fields
        @settings[:visible] = hidden_fields ? all_fields - hidden_fields : all_fields
        @settings[:invisible] = hidden_fields
      else
        @settings[:visible] = all_fields
      end
      @settings
    end

    def default_table_settings
      if %w(sold contact_later).include? params[:only]
        @entity.ADVANCED_COLUMNS
      else
        @entity.DEFAULT_COLUMNS
      end
    end

    def user_table_settings
      case params[:type]
      when 'SALE'
        if params[:only] == 'sold'
          current_user.table_settings['ADVANCED_SALE']
        else
          current_user.table_settings['DEFAULT_SALE']
        end
      when 'CANDIDATE'
        if params[:only] == 'contact_later'
          current_user.table_settings['ADVANCED_CANDIDATE']
        else
          current_user.table_settings['DEFAULT_CANDIDATE']
        end
      end
    end

    def current_key
      if %w(sold contact_later).include? params[:only]
        key = 'ADVANCED_' + params[:type]
      else
        key = 'DEFAULT_' + params[:type]
      end
      key
    end

    def table_params
      params.require(:table).permit(:type, :name, :level_id,
                                    :specialization_id,
                                    :email, :source_id,
                                    :date, :status_id,
                                    :topic, :skype,
                                    :user_id, :price,
                                    :date_end, :date_start,
                                    :reminder_date, :lead)
    end

    def sale_table
      case params[:only]
      when 'sold'
        Sale.sold
      when 'declined'
        Sale.declined
      else
        Sale.open
      end
    end

    def candidate_table
      case params[:only]
      when 'hired'
        Candidate.hired
      when 'we_declined'
        Candidate.we_declined
      when 'he_declined'
        Candidate.he_declined
      when 'contact_later'
        Candidate.contact_later
      else
        Candidate.open
      end
    end

    def paginate_table
      @table = @table.oder_date_nulls_first.paginate(page: params[:page],
                               per_page: cookies[:lid_count] || 25)
    end

    def nil_if_blank
      params[:period][:from] = nil if params[:period][:from].blank?
      params[:period][:to] = nil if params[:period][:to].blank?
    end

    def current_entity
      case params[:type]
      when 'SALE'
        @entity = Sale
      when 'CANDIDATE'
        @entity = Candidate
      end
    end

    def scoped_sale_data
      case params[:export]
      when 'sold'
        Sale.sold
      when 'declined'
        Sale.declined
      when 'open'
        Sale.open
      else
        Sale.all
      end
    end

    # NEED WRITE
    def scoped_candidate_data
    end

    # NEED OPIMIZE
    def send_remind_today
      table = Table.find(params[:id])
      return unless table.status.contact_later? && params[:table][:reminder_date]
      reminder_date = table.reminder_date
      return unless reminder_date.to_date == Date.today && reminder_date > DateTime.current
      UserMailer.remind_today(table.id)
        .deliver_later(wait_until: reminder_date)
    end

    def need_paginate?
      cookies[:lid_count] != 'all'      
    end

    def lid_count_conf
      return unless params[:lid_count]
      cookies[:lid_count] = params[:lid_count]
    end

    def not_itself_id?(id)
      return false unless id
      current_user.id != id.to_i
    end
end

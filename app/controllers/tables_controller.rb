# Main controller for work with tables
class TablesController < GridsController

  # OPTIMIZE (NEED CHANGE WORK OF CANCANCAN)
  # load_and_authorize_resource

  before_action :nil_if_blank, only: [:download_selective_xls,
                                      :download_scoped_xls]
  before_action :current_entity, only: [:download_selective_xls,
                                        :download_scoped_xls,
                                        :table_settings,
                                        :index]
  before_action :lid_count_conf, only: :index
  before_action :current_table_settings, only: [:index, :table_settings]
  after_action :send_remind_today, only: :update
  before_action :check_duplicate_data, only: :update

  include ApplicationHelper

  def index
    case params[:type]
    when 'CANDIDATE'
      @value_for_description = SimpleText.text_for_candidate
    when 'SALE'
      @value_for_description = "" # NEED WRITE
    end
    @q = q_sort
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
    object.update_attribute(:date, object.created_at)
    Statistic.update_statistics(object)
    History.create_history_for_new_object(object)
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
    History.create_history_for_update_object(table, params[:table])
    if @candidates
      render json: { pseudo_uniq: 'exist', candidates: @candidates, id: params[:id] }.to_json
    else
      render json: 'success'.to_json
    end
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

    def table_params
      params.require(:table).permit(:type, :name, :level_id,
                                    :specialization_id,
                                    :email, :source_id,
                                    :date, :status_id,
                                    :topic, :skype,
                                    :user_id, :price,
                                    :date_end, :date_start,
                                    :reminder_date, :phone)
    end  

    def pseudo_uniq_params
      params.require(:table).permit(:skype, :phone, :email)
    end

    def nil_if_blank
      params[:period][:from] = nil if params[:period][:from].blank?
      params[:period][:to] = nil if params[:period][:to].blank?
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

    def check_duplicate_data
      return unless pseudo_unique?
      @candidates = Candidate.where(pseudo_uniq_params)
    end

    def pseudo_unique?
      return false unless params[:type] == 'CANDIDATE'
      params[:table][:skype] || params[:table][:phone] || params[:table][:email]
    end
end

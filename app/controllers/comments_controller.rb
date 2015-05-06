class CommentsController < GridsController
  before_action :current_entity, only: :create
  before_action :current_table_settings, only: :create

  include ApplicationHelper

  def create
    table = Table.find(params[:table_id])
    time = DateTime.now
    comment = table.comments.create(user_id: current_user.id,
                                    body: params[:body],
                                    datetime: time)
    ubdate_table_date table
    render json: { comment: generate_comment(comment, time).html_safe,
                   table: @table_page }.to_json 
  end

  def destroy
    Comment.find(params[:id]).destroy
  end

  private

    def ubdate_table_date(table)
      table.update_attribute(:date, DateTime.now)
      @q = q_sort
      @table = @q.result.oder_date_nulls_first
      paginate_table if need_paginate?
      @table_page = view_context.render 'tables/table_body'
    end
end

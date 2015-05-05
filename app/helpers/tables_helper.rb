# Here main generator for table view
module TablesHelper
  EXPORT_FIELDS_SALE = { name: :name,
                         email: :email,
                         source: :source_id,
                         date: :date,
                         status: :status_id,
                         topic: :topic,
                         skype: :skype,
                         user: :user_id }

  def export_field
    case params[:type]
    when 'SALE'
      export_fields_sale
    when 'CANDIDATE'
      export_field_candidate
    end
  end

  def export_fields_sale
    content_tag(:td, '', id: 'fields') do
      buffer = ActiveSupport::SafeBuffer.new
      EXPORT_FIELDS_SALE.each do |key, value|
        buffer << check_box_tag(key, key, false, name: 'fields[]', value: value)
        buffer << label_tag(key)
        buffer << tag(:br)
      end
      buffer
    end
  end

  # NEED WRITE
  def export_field_candidate
  end

  def export_users_fields
    case params[:type]
    when 'SALE'
      User.seller
    when 'CANDIDATE'
      User.hh
    end
  end

  def table_generation(table)
    return if table.empty?
    buffer = ActiveSupport::SafeBuffer.new
    buffer << generate_head(table)
    buffer << generate_table_body(table)
    buffer
  end

  def generate_head(entity)
    content_tag(:thead) do
      content_tag(:tr, class: 'info') do
        concat generate_head_item('#')
        concat generate_head_item('Id', 'context')        if present? :id
        concat generate_head_item('Name', 'context')      if present? :name
        concat generate_sortable_th('sort', 'Lead',
                                    :lead)                if present? :lead
        concat generate_sortable_th('sort', 'Level',
                                    :level_name)          if present? :level
        concat generate_sortable_th('sort',
                                    'Specialization',
                                    :specialization_name) if present? :specialization
        concat generate_head_item('Topic', 'context')     if present? :topic
        concat generate_sortable_th('sort context',
                                    'Source',
                                    :source_name)         if present? :source
        concat generate_head_item('Skype', 'context')     if present? :skype
        concat generate_head_item('Email', 'context')     if present? :email
        concat generate_head_item('Links', 'context')     if present? :links
        concat generate_sortable_th('sort context',
                                    'Date',
                                    :date)                if present? :date
        concat generate_sortable_th('sort context',
                                    'Assign to',
                                    :user_id)             if present? :user
        concat generate_sortable_th('sort context',
                                    'Status',
                                    :status_id)           if present? :status
        concat generate_head_item('Price',
                                  'context')              if present? :price
        concat generate_head_item('Terms', 'context')     if present? :terms
        concat content_tag(:th, 'Reminder')               if present? :reminder
        concat generate_head_item('Comments', 'context')  if present? :comments
      end
    end
  end

  def generate_table_body(table)
    content_tag(:tbody, class: 'table-body') do
      table.each do |entity|
        concat generate_body entity
      end
    end
  end
  
  def generate_body(entity)
    content_tag(:tr, id: entity.id, class: generate_class_tr(entity.user_id)) do
      concat table_control        entity.id
      concat table_id             entity.id                if present? :id
      concat table_name           entity.name              if present? :name
      concat table_lead           entity.lead              if present? :lead
      concat table_level          entity.level_id          if present? :level
      concat table_specialization entity.specialization_id if present? :specialization
      concat table_topic          entity.topic             if present? :topic
      concat table_source         entity.source_id         if present? :source
      concat table_skype          entity.skype             if present? :skype
      concat table_email          entity.email             if present? :email
      concat table_links          entity.links             if present? :links
      concat table_date           entity.date              if present? :date
      concat table_user           entity.user_id           if present? :user
      concat table_status         entity.status_id         if present? :status
      concat table_price          entity.price             if present? :price
      concat table_period         entity.date_start,
                                  entity.date_end          if present? :terms
      concat table_reminder       entity.reminder_date     if present? :reminder
      concat table_comments       entity.comments          if present? :comments
    end
  end

  def present?(column)
    @settings[:visible].include? column
  end
  
  def generate_head_item(name,
                         class_names = '')
    content_tag(:th, name,
                class: class_names)
  end

  def generate_sortable_th(class_names, name, value)
    content_tag(:th, sort_link(@q, value, name),  class: class_names)
  end

  def generate_class_tr(user_id)
    return if params[:type] == 'CANDIDATE'
    user_id == current_user.id ? 'user_owner' : nil
  end

  def table_control(id)
    content_tag(:td, '', class: 'controlls') do
      name = 'row' + id.to_s
      check_box_tag(name, id, false, class: 'controll')
    end
  end

  def table_id(id)
    content_tag(:td, id, class: 'id',
                name: "row#{id}", value: 'id')
  end

  def table_reminder(date_time)
    content_tag(:td, date_time,
                class: 'date-time-editable td-reminder',
                name: 'table[reminder_date]', value: 'reminder_date')
  end


  def table_name(name)
    content_tag(:td, name,
                class: 'editable-field td-name',
                name: 'table[name]', value: 'name')
  end

  def table_lead(lead)
    content_tag(:td, '', class: 'td-lead') do
      select_field_with_no_selected(:table, :lead, (1..10).to_a, lead)
    end
  end

  def table_level(level_id)
    content_tag(:td, '', class: 'td-level-id') do
      select_field_with_no_selected(:table, :level_id,
                   Level.all.collect { |l| [l.name.capitalize, l.id] },
                   level_id)
    end
  end

  def table_specialization(specialization_id)
    content_tag(:td, '', class: 'td-specialization-id') do
      select_field_with_no_selected(:table, :specialization_id,
                   Specialization.all.collect { |s| [s.name.capitalize, s.id] },
                   specialization_id)
    end
  end

  def table_email(email)
    content_tag(:td, email,
                class: 'editable-field td-email',
                name: 'table[email]',
                value: 'email')
  end

  def table_source(source_id)
    content_tag(:td, '', class: 'td-source-id') do
      select_field_with_no_selected(:table, :source_id,
                   Source.all.where(for_type: params[:type].downcase).collect { |s| [s.name.capitalize, s.id] },
                   source_id)
    end
  end

  def table_date(date)
    content_tag(:td, '', class: 'td-date') do
      content_tag(:input, '',
                  name: 'table[date]',
                  value: date, class: 'date-input')
    end
  end

  def table_status(status_id)
    content_tag(:td, '', class: 'td-status-id') do
      select_field(:table, :status_id,
                 Status.all.where(for_type: params[:type].downcase).collect { |s| [s.name.capitalize, s.id] },
                 status_id)
    end
  end

  def table_topic(topic)
    content_tag(:td, topic,
                class: 'editable-field td-topic',
                name: 'table[topic]',
                value: 'topic')
  end

  def table_user(user_id)
    content_tag(:td, '', class: 'td-user-id') do
      select_field(:table, :user_id,
                   users.collect { |s| [s.full_name, s.id] }, user_id)
    end
  end

  def users
    case params[:type]
    when 'SALE'
      User.seller
    when 'CANDIDATE'
      User.hh
    end
  end

  def table_price(price)
    content_tag(:td, price,
                class: 'editable-field td-price',
                name: 'table[price]',
                value: 'price')
  end

  def table_skype(skype)
    content_tag(:td, skype,
                class: 'editable-field td-skype ',
                name: 'table[skype]',
                value: 'skype')
  end

  def table_period(date_start, date_end)
    content_tag(:td, '', class: 'td-period') do
      concat content_tag(:label, 'Start:')
      concat content_tag(:input, '',
                         name: 'table[date_start]',
                         class: 'date-input period-date-start',
                         value: date_start)
      concat content_tag(:label, 'End:')
      concat content_tag(:input, '',
                         name: 'table[date_end]',
                         class: 'date-input period-date-end',
                         value: date_end)
    end
  end

  def table_links(links)
    content_tag(:td, '', class: 'editable-activity td-links', value: 'links') do
      content_tag(:div, class: 'link_list') do
        links.each do |link|
          concat generate_link(link)
        end
      end
    end
  end

  # FIXME
  def generate_link(link)
    content_tag(:div, class: "link l_#{link.id}") do
      concat link_to(link.alt, link.href, target: '_blank')
      concat link_to(image_tag(ActionController::Base.helpers
                     .asset_path('remove-red.png')),
                     link_path(link),
                     class: 'pull-right remove-link',
                     method: :delete, remote: true)
    end
  end

  def table_comments(comments)
    content_tag(:td,
                class: 'editable-activity td-comments',
                value: 'comments') do
      content_tag(:div, class: 'comment_list') do
        comments.each do |comment|
          concat generate_comment(comment)
        end
      end
    end
  end

  def generate_comment(comment)
    content_tag(:div, class: "comment c_#{comment.id}") do
      concat comment_topic(comment)
      concat link_remove_comment(comment)
      concat content_tag(:p, auto_link(comment.body))
      concat content_tag(:div, '', class: 'clear')
    end
  end

  def comment_topic(comment)
    buffer = ActiveSupport::SafeBuffer.new
    buffer << img_field(comment.user.avatar.url(:small),
                        'pull-left comment-foto')
    buffer << span_field(comment.datetime.strftime('%e.%m %H:%M'),
                         'comment_time')
    buffer << span_field(' ' + comment.user.first_name, 'comment_time')
    buffer
  end

  def link_remove_comment(comment)
    return unless current_user == comment.user
    link_to(img_field('remove-red.png'),
            comment_path(comment),
            class: 'pull-right', method: :delete, remote: true)
  end

  def span_field(value, class_names = '')
    content_tag(:span, value, class: class_names)
  end

  def img_field(url, class_names = '')
    image_tag(url, class: class_names)
  end

  def select_field(field_name_1,
                   field_name_2,
                   collenction,
                   selected_field,
                   class_names = '')
    select(field_name_1, field_name_2,
           collenction, { selected: selected_field },
           class: class_names + 'selectable-field btn btn-default',
           fieldname: field_name_2)
  end

  def select_field_with_no_selected(field_name_1,
                                    field_name_2,
                                    collenction,
                                    selected_field,
                                    class_names = '')
    select(field_name_1, field_name_2,
           collenction, { include_blank: "Not selected", selected: selected_field },
           class: class_names + 'selectable-field btn btn-default',
           fieldname: field_name_2)
  end

  def active_link(count)
    return 'active-link-per-page' if cookies[:lid_count] == count.to_s && cookies[:lid_count] == 'all'
    return unless cookies[:lid_count].to_i == count.to_i
    'active-link-per-page'
  end
end

class MeetingsController < ApplicationController
  require 'rubygems'
  require 'google_calendar'

  def index
    @type = params[:type]
    @meeting = Meeting.last
  end


  def create
    table = Table.find(params[:@meeting][:table_id])
    @meeting = Meeting.new(meeting_params)
    @meeting.end_time = @meeting.start_time + 1.hours unless @meeting.end_time
    @meeting.table = table
    if @meeting.save
      comment = table.comments.create(user_id: current_user.id, body: "Appointed meeting #{@meeting.start_time.strftime('%Y-%m-%d %H:%M')}", datetime: Date.today)
      config = YAML.load(File.read(File.join(Rails.root, 'config', 'calendar.yml')))
      case params[:type]
      when "SALE"
        config_calendar = config['calendar_sale']
      when "CANDIDATE"
        config_calendar = config['calendar_candidate']
      end
      cal = Google::Calendar.new(:client_id     => config['client_id'],
                     :client_secret => config['client_secret'],
                     :calendar      => config_calendar,
                     :redirect_url  => config['redirect_url'],
                     :refresh_token => config['refresh_token'])
      event = cal.create_event do |e|
        e.title = @meeting.title
        e.description = @meeting.description.gsub(/\r\n/, "\\n")
        e.start_time = @meeting.start_time
        e.end_time = @meeting.end_time
        users = params[:users]
        attendees = [{'email'=> current_user.email, 'displayName' => "#{current_user.first_name} #{current_user.last_name}", 'responseStatus' => 'needsAction'}]
        (users || []).each_index do |i|
          if users[i].include?("task")
            table = Table.find_by_id(users[i].to_i)
            table.status_id =  Status.meeting_status_id(params[:type])
            table.save
            attendees[i+1] = {'email' => table.email, 'displayName' => table.name, 'responseStatus' => 'needsAction'} if table.email
          else
            user = User.find_by_id(users[i].to_i)
            attendees[i+1] = {'email' => user.email, 'displayName' => "#{user.first_name} #{user.last_name}", 'responseStatus' => 'needsAction'}
          end
        end
        attendees<<{'email'=> params[:@meeting][:email], 'displayName' => "Indefinite", 'responseStatus' => 'needsAction'} unless params[:@meeting][:email].empty?
        e.attendees = attendees
      end
      @meeting.update(event_id: event.raw["id"])
      redirect_to root_url
    else
      redirect_to root_url
    end
  end

  def update
    config = YAML.load(File.read(File.join(Rails.root, 'config', 'calendar.yml')))
    cal = Google::Calendar.new(:client_id     => config['client_id'],
                     :client_secret => config['client_secret'],
                     :calendar      => config['calendar_sale'],
                     :redirect_url  => config['redirect_url'],
                     :refresh_token => config['refresh_token'])
    binding.pry
    meeting = Meeting.where(id: params[:id]).last
    meeting.update_attributes(meeting_update_params)
    event = cal.find_event_by_id(meeting.event_id)
    event.title = @meeting.title
    event.description = @meeting.description.gsub(/\r\n/, "\\n")
    event.start_time = @meeting.start_time
    event.end_time = @meeting.end_time
    event.save
    redirect_to action: :index
  end

  def meeting_params
    params.require(:@meeting).permit(:title, :description, :start_time, :end_time)
  end
  def meeting_update_params
    params.require(:meeting).permit(:title, :description, :start_time, :end_time)
  end
end

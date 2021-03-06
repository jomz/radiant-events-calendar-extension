require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::EventsController do
  dataset :users, :events

  before(:each) do
    login_as :admin
  end

  def default_attributes
    {
      :category         => "",
      :location         => "",
      :date             => Date.today.to_s(:long),
      :'start_time(5i)' => "",
      :'end_time(5i)'   => "",
      :timezone         => "UTC",
      :filter_id        => "",
      :description      => ""
    }
  end

  describe "create" do
    integrate_views

    it "should be successful with only a name" do
      event_name = "Event with no time"
      post :create, :event => default_attributes.merge({
        :name => event_name,
      })
      response.should redirect_to(admin_events_url)
      event = Event.find_by_name(event_name)
      event.should_not be_nil
    end

    it "should be successful with only a start time" do
      event_name = "Event with only start time"
      post :create, :event => default_attributes.merge({
        :name => event_name,
        :'start_time(5i)' => "09:00:00",
      })
      response.should redirect_to(admin_events_url)
      event = Event.find_by_name(event_name)
      event.should_not be_nil
    end

    it "should be successful with a start and end time" do
      event_name = "Event with start and end time"
      post :create, :event => default_attributes.merge({
        :name             => event_name,
        :'start_time(5i)' => "09:00:00",
        :'end_time(5i)'   => "17:00:00"
      })
      response.should redirect_to(admin_events_url)
      event = Event.find_by_name(event_name)
      event.should_not be_nil
      event.start_time.to_date.should == event.end_time.to_date
    end

    it "should advance an end time to the next day" do
      event_name = "Spanning midnight"
      post :create, :event => default_attributes.merge({
        :name             => event_name,
        :date             => Date.today.end_of_year.to_s(:long),
        :'start_time(5i)' => "19:00:00",
        :'end_time(5i)'   => "01:00:00"
      })
      event = Event.find_by_name(event_name)
      event.should_not be_nil
      event.start_time.to_date.should == Date.today.end_of_year
      event.end_time.to_date.should == (Date.today >> 12).beginning_of_year
    end

    it "should not accept same start time and end time" do
      post :create, :event => default_attributes.merge({
        :name => "Same start and end times",
        :'start_time(5i)' => "19:00:00",
        :'end_time(5i)'   => "19:00:00"
      })
      response.should render_template("new")
      response.body.should have_text(Regexp.new(I18n.t("activerecord.errors.models.event.attributes.start_time.after_end_time")))
    end

    it "should require a start time with an end time" do
      post :create, :event => default_attributes.merge({
        :name => "No start time with end time",
        :'end_time(5i)' => "19:00:00"
      })
      response.should render_template("new")
      response.body.should have_text(Regexp.new(I18n.t("activerecord.errors.models.event.attributes.start_time.blank")))
    end
  end

  describe "copy" do
    it "should copy and render the new view" do
      get :copy, :id => Event.first.id
      response.should render_template("new")
      orig, copy = Event.first, assigns[:event]
      copy.new_record?.should be_true
      [ copy.name, copy.location, copy.date].should == [ orig.name, orig.location, orig.date ]
    end

    it "should fails and render the index view" do
      get :copy, :id => "foo"
      response.should redirect_to(admin_events_url)
    end
  end

  describe "auto_complete_for_event_category" do
    it "should return a list of categories" do
      xhr :get, :auto_complete_for_event_category, :event => { :category => "hol" }
      response.should be_success
      response.should have_text("<ul><li>Holidays</li></ul>")
    end
  end
end

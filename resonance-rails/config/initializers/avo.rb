# For more information regarding these settings check out our docs https://docs.avohq.io
# The values disaplayed here are the default ones. Uncomment and change them to fit your needs.
Avo.configure do |config|
  ## == Routing ==
  config.root_path = '/admin'

  ## == Licensing ==
  # config.license_key = ENV['AVO_LICENSE_KEY']

  ## == Set the context ==
  config.set_context do
    # Return a context object that gets evaluated within Avo::ApplicationController
  end

  ## == Authentication ==
  config.current_user_method = :current_user
  config.authenticate_with do
    redirect_to main_app.new_user_session_path unless current_user
  end

  ## == Customization ==
  config.click_row_to_view_record = true
  config.app_name = 'Resonance Admin'

  ## == Branding ==
  config.branding = {
    colors: {
      100 => "#CEE7F8",
      400 => "#00F2FF", # brand-primary
      500 => "#00F2FF",
      600 => "#BC00FF", # brand-secondary
    }
  }

  ## == Breadcrumbs ==
  # config.display_breadcrumbs = true
  # config.set_initial_breadcrumbs do
  #   add_breadcrumb "Home", '/avo'
  # end

  ## == Menus ==
  # config.main_menu = -> {
  #   section "Dashboards", icon: "avo/dashboards" do
  #     all_dashboards
  #   end

  #   section "Resources", icon: "avo/resources" do
  #     all_resources
  #   end

  #   section "Tools", icon: "avo/tools" do
  #     all_tools
  #   end
  # }
  # config.profile_menu = -> {
  #   link "Profile", path: "/avo/profile", icon: "heroicons/outline/user-circle"
  # }
end

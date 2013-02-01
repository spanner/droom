module NavigationHelpers
  def path_to(page_name)
    case page_name
    when /^the (?:home page|dashboard)$/
      dashboard_path
    when /^the sign up page$/
      pending ###
    when /^the (?:login|sign in|log in) page$/
      new_user_session_path
    when /^the (?:logout|sign out) page$/
      destroy_user_session_path
    else
      dashboard_path
    end
  end
end

World(NavigationHelpers)


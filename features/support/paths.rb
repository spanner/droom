module NavigationHelpers
  def path_to(page_name)
    case page_name
    when /^the (?:home page|dashboard)$/
      dashboard_path
    when /^the preferences page$/
      edit_user_path(@user)
    when /^the (?:login|sign in|log in) page$/
      new_user_session_path
    when /^the (?:logout|sign out) page$/
      destroy_user_session_path
    when /^the preferences page$/
      edit_user_path(@user)
    else
      dashboard_path
    end
  end
end

World(NavigationHelpers)


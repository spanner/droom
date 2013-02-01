module UserSessionHelper
  def login
    visit new_user_session_path
    fill_in 'Email', with: @me.email
    fill_in 'Password', with: @me.password
    click_button 'Login'
  end
end
World(UserSessionHelper)
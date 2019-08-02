# On every authenticated request, shared cookie is `set` again so that the encoded date is brought forward.
#
Warden::Manager.after_set_user do |user, warden, options|
  Rails.logger.warn "⚠️ set_last_request_at! for #{user.inspect}"
  user.set_last_request_at!
end

# We used to set shared domain cookie on sign in here
# but it proved impossible, or anyway very unreliable, to try and do that after session_limitable had set its unique_session_id.
# so now we override the call to update_unique_session_id!, which is kind of hacky but ought to work.

# Unset session id and shared domain cookie on sign out.
#
Warden::Manager.before_logout do |user, warden, options|
  Droom::AuthCookie.new(warden.cookies).unset
  user.reset_session_ids! if user
end
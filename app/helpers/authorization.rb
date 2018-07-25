class Courier::Middleware::JWTToken
  def user_id
    payload['uid']
  end
end

module Authorization
  def require_token(env)
    return Twirp::Error.unauthenticated 'No auth token given' unless env[:token]
    yield
  end

  def require_user(env, id: nil, name: nil)
    require_token env do
      if id
        return forbidden_error unless env[:token].user_id == id
      end

      if name
        return forbidden_error unless env[:token].sub == name
      end

      yield
    end
  end

  private

  def forbidden_error
    Twirp::Error.resource_exhausted 'You cannot perform this action'
  end
end

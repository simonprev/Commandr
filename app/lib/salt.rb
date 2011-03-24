def salt username, password
  return Digest::SHA1.hexdigest(username+"0"+password)
end

def set_encrypted_password(password,user)
  @password=Digest::SHA1.hexdigest(password)
  @salted_password=salt user.username, @password
  user.password=@salted_password
  user.save
end

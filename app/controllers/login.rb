#-------------------------------#
#           Commandr            #
#-----Auteur: Simon Prévost-----#


module LoginController
  def self.included( app )

    app.get '/login' do #{{{
      @titre="Connexion"
      @template="formulaire"
      haml :'user/login'
    end #}}}

    app.post '/login' do #{{{

      @user=User.first(:username=>params[:username])
      @password=Digest::SHA1.hexdigest(params[:password])


      if @user && salt(params[:username],@password)==@user.password
        session["username"]||=@user.username
        session["id"]||=@user.id
        redirect "/users/#{session["username"]}"
      else
        @erreur="Les informations de connexion sont invalides"
        @template="formulaire"
        haml :'user/login'
      end

    end #}}}

    app.get '/logout' do #{{{

      session["username"]=nil
      session["id"]=nil
      redirect "/login"

    end #}}}


  end
end


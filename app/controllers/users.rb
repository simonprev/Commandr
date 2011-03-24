#-------------------------------#
#           Commandr            #
#-----Auteur: Simon Prévost-----#

#Fonctions pour user
# LIST
# NEW
# CREATE
# SHOW
# FOLLOW
# UNFOLLOW
# EDIT

module UsersController
  def self.included (app)

    app.before %r{/users/([\w]+)} do |user|
      @user=User.first(:username=>user)
    end

    app.before %r{^/users/?} do
      @user_tri = case params[:tri]
        when nil: :count_followers.desc
        when "abonnes": :count_followers.desc
        when "publications": :count_works.desc
        when "username": :username.asc
        when "derniere": :derniere_publication.desc
      end
    end

    #LIST
    app.get '/users' do #{{{
      @titre="Auteurs"
      set_pagination User.all().count, params[:page]
      @users=User.all().page @page, :order=>@user_tri
      @template="auteurs"
      return request.xhr? ? users_json(@users) : haml(:'user/index')
    end #}}}

    #NEW
    app.get '/users/new' do #{{{
      @user=User.new
      @template="formulaire"
      haml :'user/new'
    end #}}}

    #CREATE
    app.post '/users/new' do #{{{
      @user=User.new :nom=>params[:nom], 
                     :prenom=>params[:prenom], 
                     :username=>params[:username],
                     :password=>params[:password],
                     :twitter_username=>params[:twitter_username],
                     :site_web=>params[:site_web],
                     :desc=>params[:desc]

      if @user.save
        session["username"]=@user.username
        session["id"]=@user.id
        set_encrypted_password(params[:password],@user)
        flash[:notice] = "L'utilisateur a été créé avec succès"
        redirect "/users/#{params[:username]}"
      else
        @template="formulaire"
        haml :"user/new"
      end
    end #}}}

    #EDIT
    app.get '/users/:user/parametres' do #{{{
      @titre="Paramètres de #{params[:user]}"
      @template="formulaire"
      @user==@self ? haml(:"user/edit") : redirect("/users/#{params[:user]}")
    end #}}}

    #SAVE EDIT
    app.post '/users/:user/parametres' do #{{{
      @user=User.first(:username=>session["username"])
      if @user.update :nom=>params[:nom],
                      :prenom=>params[:prenom],
                      :site_web=>params[:site_web],
                      :twitter_username=>params[:twitter_username],
                      :desc=>params[:desc]


        session["username"]=@user.username
        flash[:notice] = "\"#{@user.username}\" a été modifiée avec succès"
        redirect "/users/#{@user.username}"
      else
        @template="formulaire"
        haml :"user/edit"
      end
    end #}}}


    #SHOW
    app.get '/users/:user' do #{{{
      @titre="#{params[:user]}"

      if @user
        favorite=@user.favorites.collect {|x| x.work_id } if params[:tri]=="favoris"
        case params[:tri]
          when "recent":    @work_tri=:created_at.desc;                         select={:user_id=>@user.id}
          when "populaire": @work_tri=[:views.desc,:created_at.desc];           select={:user_id=>@user.id}
          when "favoris":   @work_tri=[:count_favorite.desc,:created_at.desc];  select={:id=>favorite}
          else              @work_tri=:created_at.desc;                         select={:user_id=>@user.id}
        end
        @count=Work.all(select).count
        set_pagination @count,params[:page]

        @feed=Work.all(select).page @page, :order=>@work_tri
        return request.xhr? ? works_json(@feed) : haml(:'user/show')
      else
        404
      end

    end #}}}

    #FOLLOW or UNFOLLOW
    app.post '/users/:user' do #{{{

      if @self && !@self.follows.include?(@user)
        @f=Fellowship.create(:source => @self, :target=> @user)
        flash[:notice]="Vous êtes maintenant abonnés à #{params[:user]}"
      else
        @f=Fellowship.first(:source => @self, :target=> @user)
        @f.destroy
        flash[:notice]="Vous n'êtes plus abonnés à #{params[:user]}"
      end
      redirect "/users/#{params[:user]}"
    end #}}}

    #LIST ABONNÉS
    app.get '/users/:user/abonnes' do #{{{
      @titre="Abonnés de #{params[:user]}"

      followers=Fellowship.all(:target_id=>@user.id).collect {|i| User.get(i.source_id).id}

      set_pagination followers.size,params[:page]
      @template="auteurs"
      @users=User.all(:id=>followers).page @page, :order=>@user_tri
      return request.xhr? ? users_json(@users) : haml(:'user/index')
    end #}}}

    #LIST ABONNEMENTS
    app.get '/users/:user/abonnements' do #{{{
      @titre="Abonnements de #{params[:user]}"

      follows=@user.follows.collect {|x| x.id }
      set_pagination follows.size,params[:page]
      @template="auteurs"
      @users=User.all(:id=>follows).page @page, :order=>@user_tri
      return request.xhr? ? users_json(@users) : haml(:'user/index')
    end #}}}

    app.get '/users/:user/profil' do #{{{
      @titre="Profile de #{params[:user]}"
      @user=User.first(:username=>params[:user])
      haml :"user/profil"
    
    end #}}}

  end
end


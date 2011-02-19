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
    
    #LIST
    app.get '/user' do #{{{

      @count=User.all(:order=>:updated_at.desc).count
      set_pagination @count,params[:page]

      @users=User.all().page @page, :order=>:updated_at.desc
      haml :'user/index'

    end #}}}

    #NEW
    app.get '/user/new' do #{{{
      @user=User.new
      haml :'user/new'
    end #}}}

    #CREATE
    app.post '/user/new' do #{{{

      @user=User.new :nom=>params[:nom], 
                     :prenom=>params[:prenom], 
                     :username=>params[:username],
                     :site_web=>params[:site_web],
                     :desc=>params[:desc],
                     :twitter_username=>params[:twitter_username]

      if params[:password].length >= 4 && params[:password].length <= 20
        @password=Digest::SHA1.hexdigest(params[:password])
        @salted_password=salt params[:username], @password
        @user.password=@salted_password
      else
        @user.password=params[:password]
        @mauvais_password=true
      end

      if @user.save
        session["username"]=@user.username
        session["id"]=@user.id
        redirect "/user/#{params[:username]}"
      else
        @user.errors.add(:password,"Le mot de passe doit contenir entre 4 et 20 caractères") if @mauvais_password
        haml :"user/new"
      end
    end #}}}

    #SHOW
    app.get '/user/:user' do #{{{
      @titre="#{params[:user]}"
      set_self session["username"]
      @user=User.first(:username=>params[:user])

      @count=Work.all(:user_id=>@user.id).count
      set_pagination @count,params[:page]

      @tri=params[:tri] || "recent"

      if @tri=="recent" || !@tri
        #sortby Date de création!
        @feed=Work.all(:user_id=>@user.id).page @page, :order=>:created_at.desc
      elsif @tri=="populaire"
        #sortby Views!
        @feed=Work.all(:user_id=>@user.id).page @page, :order=>[:views.desc,:created_at.desc]
      elsif @tri=="favoris"
        #sortby Favorited!
        @feed=Work.all(:user_id=>@user.id).page @page, :order=>[:count_favorite.desc,:created_at.desc]
      end

      haml :'publication/index'

    end #}}}

    #FOLLOW or UNFOLLOW
    app.post '/user/:user' do #{{{
      set_self session["username"]
      @user=User.first(:username=>params[:user])

      if !@self.follows.include? @user
        @f=Fellowship.new(:source => @self, :target=> @user)
        @f.save
      else
        @f=Fellowship.first(:source => @self, :target=> @user)
        @f.destroy
      end

      redirect "/user/#{params[:user]}"

    end #}}}

    #EDIT
    app.get '/parametres' do #{{{
      if session["username"]
        @user=User.first(:username=>session["username"])
        haml :"user/edit"
      else
        redirect "/login"
      end
    end #}}}

    #SAVE EDIT
    app.post '/parametres' do #{{{

      @user=User.first(:username=>session["username"])
      if @user.update :nom=>params[:nom],
                      :prenom=>params[:prenom],
                      :site_web=>params[:site_web],
                      :twitter_username=>params[:twitter_username]


        redirect "/user/#{@user.username}"
      else
        p @user.errors
        haml :"user/edit"
      end
    end #}}}

  end
end


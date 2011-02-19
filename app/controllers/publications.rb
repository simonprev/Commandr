#-------------------------------#
#           Commandr            #
#-----Auteur: Simon Prévost-----#

#Fonctions pour publication
# LIST(FEED|ALL|CODES|IMAGES)
# NEW(CHOIX|CODE|IMAGE)
# CREATE(CODE|IMAGES)
# SHOW
# FAVORIS
# DELETE
# EDIT
# CREATE COMMENTAIRE

module PublicationsController
  def self.included( app )

    #LIST FEED
    app.get '/feed' do #{{{
      if session["username"]
        @titre="Dernières Activités"
        set_self session["username"]
        @follows=@self.follows.collect {|x| x.id }
        @follows << @self.id

        @tri="feed"

        @count=Work.all(:user_id=>1).count
        set_pagination @count,params[:page]

        @feed=Work.all(:order=>:updated_at.desc, :user_id=>@follows).page @page

        return works_json @feed if request.xhr?

        haml :'publication/index'

      else
        redirect '/publication'
      end
    end #}}}

    #LIST ALL
    app.get '/publication' do #{{{
      p salt("cool","cool")
      @titre="Publications"
      set_self session["username"]

      @count=Work.all.count
      set_pagination @count,params[:page]

      @tri=params[:tri] || "recent"

      if @tri=="recent" || !@tri
        #sortby Date de création!
        @feed=Work.all().page @page, :order=>:updated_at.desc
      elsif @tri=="populaire"
        #sortby Views!
        @feed=Work.all().page @page, :order=>[:views.desc,:updated_at.desc]
      elsif @tri=="favoris"
        #sortby Favorited!
        @feed=Work.all().page @page, :order=>[:count_favorite.desc,:updated_at.desc]
      end

      return works_json @feed if request.xhr?

      haml :'publication/index'

    end #}}}


    #LIST CODES
    app.get '/code' do #{{{
      @titre="Codes"
      set_self session["username"]

      @count=Work.all(:type.not=>"image").count
      set_pagination @count,params[:page]

      @tri=params[:tri] || "recent"

      if @tri=="recent" || !@tri
        #sortby Date de création!
        @feed=Work.all(:type.not=>"image").page @page, :order=>:updated_at.desc
      elsif @tri=="populaire"
        #sortby Views!
        @feed=Work.all(:type.not=>"image").page @page, :order=>[:views.desc,:updated_at.desc]
      elsif @tri=="favoris"
        #sortby Favorited!
        @feed=Work.all(:type.not=>"image").page @page, :order=>[:count_favorite.desc,:updated_at.desc]
      end

      return works_json @feed if request.xhr?

      haml :'publication/index'


    end #}}}

    #LIST IMAGES
    app.get '/image' do #{{{
      @titre="Images"
      set_self session["username"]

      @count=Work.all(:type=>"image").count
      set_pagination @count,params[:page]

      @tri=params[:tri] || "recent"

      if @tri=="recent" || !@tri
        #sortby Date de création!
        @feed=Work.all(:type=>"image").page @page, :order=>:updated_at.desc
      elsif @tri=="populaire"
        #sortby Views!
        @feed=Work.all(:type=>"image").page @page, :order=>[:views.desc,:updated_at.desc]
      elsif @tri=="favoris"
        #sortby Favorited!
        @feed=Work.all(:type=>"image").page @page, :order=>[:count_favorite.desc,:updated_at.desc]
      end

      return works_json @feed if request.xhr?

      haml :'publication/index'

    end #}}}

    #NEW
    app.get '/new' do #{{{

      if session["username"]
        haml :'publication/new'
      else
        redirect '/login'
      end

    end #}}}

    #NEW CODE
    app.get '/new_code' do #{{{

      if session["username"]
        haml :'publication/new_code'
      else
        redirect '/login'
      end

    end #}}}

    #CREATE CODE
    post '/new_code' do #{{{
      @self = User.first(:username=>session["username"])

      @work = Work.new(:titre => params[:work_title],
                       :body  => params[:work_body],
                       :desc => params[:work_desc],
                       :type  => params[:work_lang],
                       :user_id=>session["id"]
                       )

      @self.update!(:updated_at=>Time.now)

      if @work.save
        redirect "/#{@work.id}"
      else
        haml :'publciation/new_code'
      end

    end #}}}

    #NEW IMAGE
    get '/new_image' do #{{{

      if session["username"]
        haml :'publication/new_image'
      else
        redirect '/login'
      end

    end #}}}

    #CREATE IMAGE
    post '/new_image' do #{{{
      @work = Work.new(:titre => params[:work_title],
                       :body => "Aucun code pour une image",
                       :desc => params[:work_desc],
                       :type  => "image",
                       :created_at => Time.now.to_i,
                       :user_id=>session["id"]
                       )

      #UPLOAD D'IMAGE EN DÉVELOPPEMENT (aucunement sécuritaire)
      if @work.save && params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
        File.open(File.join(Dir.pwd,"public/files", @work.id.to_s), "wb") { |f| f.write(tmpfile.read) }
        redirect "/#{@work.id}"
      else
        unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
          @work.errors.add :fichier,"Vous devez choisir un fichier"
        end
        haml :'publication/new_image'
      end

    end #}}}
   
    #SHOW
    app.get %r{^\/([0-9]{0,4})$} do |id| #{{{

      set_self session["username"]
      @code=Work.get(id)
      if @code
        @user=@code.user
        @comments=Comment.all(:work_id=>id)
        @is_favorite=is_favorite @self,@code

        if !session["views"]
          session["views"]=[]
        end

        if !session["views"].include? id.to_i
          session["views"] << id.to_i
          @code.update!(:views=>@code.views+1)
        end

        haml :'publication/show'
      else
        redirect "/cannot_find_what_you_are_looking_for_sorry"
      end

    end #}}}

    #FAVORIS
    app.get '/:id/fav' do #{{{
      @self=User.first(:fields=>[:id,:username],:username=>session["username"])
      @code=Work.first(:fields=>[:id], :id=>params[:id])
      @count_fav=@code.count_favorite

      @is_favorite=Favorite.is_favorite @self,@code

      if @is_favorite
        @code.update!(:count_favorite=>@count_fav-1)
        Favorite.first(:user=>@self,:work=>@code).destroy
      else
        @code.update!(:count_favorite=>@count_fav+1)
        Favorite.create(:user=>@self,:work=>@code)
      end

      redirect "/#{params[:id]}"


    end #}}}

    #CREATE COMMENTAIRE
    app.post '/:id' do #{{{

      @comment=Comment.create(:nom  => session["username"],
                              :body => params[:comment_body],
                              :work_id=>params[:id],
                              :user_id=> session["id"])

      redirect "/#{params[:id]}"


    end #}}}

    #DELETE
    app.delete '/delete/:id' do #{{{

      @code=Work.get(params[:id])

      if @code.destroy
        redirect "/"
      else
        redirect"/#{params[:id]}"
      end

    end #}}}

    #EDIT
    app.get '/edit/:id' do #{{{

      @code=Work.get(params[:id])
      if session["id"]==@code.user_id
        haml :'publication/edit'
      else
        redirect "/#{params[:id]}"
      end

    end #}}}

    #SAVE EDIT
    app.put "/edit/:id" do #{{{
      @error=[]
      @code=Work.first(params[:id])
      if params[:work_title]==""
        @error.push "Le titre ne doit pas être vide"
      end
      if params[:work_body]==""
        @error.push "Le contenu ne doit pas être vide"
      end

      @code.update!(:titre => params[:work_title],:body  => params[:work_body],:updated_at=> Time.now) if @error.empty?

      if @error.empty?
        redirect "/#{params[:id]}"
      else
        haml :modify
      end
    end #}}}
  end
end

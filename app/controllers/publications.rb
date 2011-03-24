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
  include Magick 
  def self.included( app )

    #LIST FEED
    app.get '/feed' do #{{{
      if session["username"]
        @titre="Dernières Activités"
        follows=@self.follows.collect {|x| x.id }
        follows << @self.id

        count=Work.all(:user_id=>follows).count
        set_pagination count,params[:page]

        @feed=Work.all(:order=>:updated_at.desc, :user_id=>follows).page @page

        return request.xhr? ? works_json(@feed) : haml(:'publication/index')
      else
        redirect '/publication'
      end
    end #}}}

    #LIST ALL
    app.get '/publications' do #{{{
      @titre="Publications - Tout"
      case params[:tri]
        when "recent":    @work_tri=:created_at.desc;
        when "populaire": @work_tri=[:views.desc,:created_at.desc];
        when "favoris":   @work_tri=[:count_favorite.desc,:created_at.desc];
        else              @work_tri=:created_at.desc;
      end
      @count=Work.all().count
      set_pagination @count,params[:page]

      @feed=Work.all().page @page, :order=>@work_tri
      @work_tri=params[:tri] || "recent"
      return request.xhr? ? works_json(@feed) : haml(:'publication/index')
    end #}}}

    #LIST CODES
    app.get '/publications/codes' do #{{{
      @titre="Publications - Codes"
      case params[:tri]
        when "recent":    @work_tri=:created_at.desc;
        when "populaire": @work_tri=[:views.desc,:created_at.desc];
        when "favoris":   @work_tri=[:count_favorite.desc,:created_at.desc];
        else              @work_tri=:created_at.desc;
      end
      @count=Work.all(:type.not=>"image").count
      set_pagination @count,params[:page]

      @feed=Work.all(:type.not=>"image").page @page, :order=>@work_tri
      @work_tri=params[:tri] || "recent"
      return request.xhr? ? works_json(@feed) : haml(:'publication/index')
    end #}}}

    #LIST IMAGES
    app.get '/publications/images' do #{{{
      @titre="Publications - Images"
      case params[:tri]
        when "recent":    @work_tri=:created_at.desc;
        when "populaire": @work_tri=[:views.desc,:created_at.desc];
        when "favoris":   @work_tri=[:count_favorite.desc,:created_at.desc];
        else              @work_tri=:created_at.desc;
      end
      @count=Work.all(:type=>"image").count
      set_pagination @count,params[:page]

      @feed=Work.all(:type=>"image").page @page, :order=>@work_tri
      @work_tri=params[:tri] || "recent"
      return request.xhr? ? works_json(@feed) : haml(:'publication/index')    end #}}}

    #NEW
    app.get '/publications/new' do #{{{
      @titre="Nouvelle Publication"
      session["username"] ? haml(:"publication/new") : redirect("/login")
    end #}}}

    #NEW CODE
    app.get '/publications/new/code' do #{{{

      @titre="Nouvelle Publication - Code"
      if session["username"]
        @post=Work.new
        @template="formulaire"
        haml :'publication/new_code'
      else
        redirect '/login'
      end
    end #}}}

    #CREATE CODE
    app.post '/publications/new/code' do #{{{

      @post = Work.new(:titre => params[:work_title],
                       :body  => params[:work_body],
                       :desc => params[:work_desc],
                       :type  => params[:work_lang],
                       :user_id=>session["id"]
                       )

      @self.update!(:updated_at=>Time.now)

      if @self && @post.save
        flash[:notice] = "La publication a été sauvegardée avec succès"
        redirect "/publications/#{@post.id}"
      else
        @template="formulaire"
        haml :'publication/new_code'
      end

    end #}}}

    #NEW IMAGE
    app.get '/publications/new/image' do #{{{
      if session["username"]
        @titre="Nouvelle Publication - Image"
        @post=Work.new
        @template="formulaire"
        haml :'publication/new_image'
      else
        redirect '/login'
      end
    end #}}}

    #CREATE IMAGE
    app.post '/publications/new/image' do #{{{
      @post = Work.new(:titre => params[:work_title],
                       :body => "Aucun code pour une image",
                       :desc => params[:work_desc],
                       :type  => "image",
                       :user_id=>session["id"]
                       )

        unless params[:file]
          erreur_file=true
        else
          titre_image=@post.titre.gsub(/[\.\s !éçÇâàÀÂÉÈôÖôöè]/,"")
          @post.file = @post.make_paperclip_mash(params[:file],titre_image+@post.user_id.to_s)
        end


        if !erreur_file && @post.save
          ext=@post.file_file_name.partition "."
          # concatène "." + "format"
          ext=ext[1]+ext[2]
          image=Image.read("#{Dir.pwd}/public/files/images/"+titre_image+@post.user_id.to_s+ext).first
          thumb=image.crop!(0,0,125,55)
          thumb.write("#{Dir.pwd}/public/files/thumbs/thumb_"+titre_image+@post.user_id.to_s+ext)

          flash[:notice] = "La publication a été sauvegardée avec succès"
          @self.update!(:updated_at=>Time.now)
          redirect "/publications/#{@post.id}"
        else
          @post.valid?
          @post.errors.add(:fichier,"Vous devez choisir un fichier") if erreur_file
          @template="formulaire"
          haml :'publication/new_image'
        end

    end #}}}

    #SHOW
    app.get %r{^\/publications/([0-9]{0,4})$} do |id| #{{{
      @post=Work.get(id)
      if @post
        @titre=@post.titre+" - "+@post.user.username
        @user=@post.user
        @comments=@post.comments
        @is_favorite=is_favorite @self,@post

        if !session["views"]
          session["views"]=[]
        end

        if !session["views"].include? id.to_i
          session["views"] << id.to_i
          @post.update!(:views=>@post.views+1)
        end

        @template="show_publication"
        haml :'publication/show'
      else
        404
      end

    end #}}}

    #FAVORIS
    app.get %r{^\/publications/([0-9]{0,4})/fav$} do |id|#{{{
      @post=Work.first(:fields=>[:id], :id=>id)
      @count_fav=@post.count_favorite

      @is_favorite=is_favorite @self,@post

      if @is_favorite
        @post.update!(:count_favorite=>@count_fav-1)
        flash[:notice] = "\"#{@post.titre}\" a été retiré de vos favoris"
        Favorite.first(:user=>@self,:work=>@post).destroy
      else
        @post.update!(:count_favorite=>@count_fav+1)
        flash[:notice] = "\"#{@post.titre}\" a été ajouté à vos favoris"
        Favorite.create(:user=>@self,:work=>@post)
      end

      if request.xhr?
        return @count_fav
      else
        redirect "/publications/#{id}"
      end

    end #}}}

    #CREATE COMMENTAIRE
    app.post %r{^\/publications/([0-9]{0,4})$} do |id| #{{{

      @comment=Comment.new(:nom  => session["username"],
                              :body => params[:comment_body],
                              :work_id=>id,
                              :user_id=> session["id"])

      if @comment.save then
        flash[:notice] = "Vote commentaire a été sauvegardé avec succès"
      end
      redirect "/publications/#{id}"

    end #}}}

    #DELETE
    app.delete %r{^\/publications/([0-9]{0,4})$} do |id|#{{{

      @post=Work.get(id)

      if @post.destroy
        flash[:notice] = "\"#{@post.titre}\" a été effacée avec succès"
        redirect "/publications"
      else
        flash[:notice] = "Suppression de \"#{@post.titre}\" échouée"
        redirect"/publications/#{id}"
      end

    end #}}}

    #EDIT
    app.get %r{^\/publications/([0-9]{0,4})/edit$} do |id|#{{{

      @post=Work.get(id)
      @titre=@post.titre+" - Modification"
      if session["id"]==@post.user_id
        @template="formulaire"
        haml :'publication/edit'
      else
        redirect "/publications/#{id}"
      end

    end #}}}

    #SAVE EDIT
    app.post %r{^\/publications/([0-9]{0,4})/edit$} do |id|#{{{
      @post=Work.get(id)
      if @post.type=="image"
        @post.body="Aucun code pour une image"
      else
        @post.body=params[:body]
      end
      @post.titre=params[:title]
      @post.desc=params[:desc]

      if @post.save
        flash[:notice] = "\"#{@post.titre}\" a été modifiée avec succès"
        redirect "/publications/#{id}"
      else
        @template="formulaire"
        @post.titre=Work.get(id).titre
        haml :'publication/edit'
      end
    end #}}}
  end
end

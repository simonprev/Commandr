#-------------------------------#
#           Commandr            #
#-----Auteur: Simon Prévost-----#

#Fonctions pour types
# LIST

module TypesController
  def self.included( app )

    #LIST ALL
    app.get '/type' do #{{{

      haml :'type/index'

    end #}}}

    #LIST TYPE
    app.get '/type/:type' do #{{{

      set_self session["username"]
      @titre="Publications - #{params[:type].capitalize}"

      @count=Work.all(:type=>params[:type]).count
      set_pagination @count,params[:page]

      @tri=params[:tri] || "recent"

      if @tri=="recent" || !@tri
        #sortby Date de création!
        @feed=Work.all(:type=>params[:type]).page @page, :order=>:created_at.desc
      elsif @tri=="populaire"
        #sortby Views!
        @feed=Work.all(:type=>params[:type]).page @page, :order=>[:views.desc,:created_at.desc]
      elsif @tri=="favoris"
        #sortby Favorited!
        @feed=Work.all(:type=>params[:type]).page @page, :order=>[:count_favorite.desc,:created_at.desc]
      end

      haml :'publication/index'

    end #}}}

  end
end


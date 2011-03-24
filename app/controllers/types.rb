#-------------------------------#
#           Commandr            #
#-----Auteur: Simon Prévost-----#

#Fonctions pour types
# LIST

module TypesController
  @@types=%w(html ruby jscript java css php c perl python sql actionscript3 scss image)
  def self.included( app )

    #LIST ALL
    app.get '/types' do #{{{
      @titre="Types"

      count_type={}

      @@types.each do |type|
        count_type[type]=Work.all(:type=>type).count
      end

      @count_type=count_type.sort{|a,b| b[1]<=>a[1]}
      @template="types"

      haml :'type/index'

    end #}}}

    #LIST TYPE
    app.get '/types/:type' do #{{{
      if @@types.include? params[:type] then
        @titre="Types - #{params[:type].capitalize}"

        case params[:tri]
          when "recent":    @work_tri=:created_at.desc;
          when "populaire": @work_tri=[:views.desc,:created_at.desc];
          when "favoris":   @work_tri=[:count_favorite.desc,:created_at.desc];
          else              @work_tri=:created_at.desc;
        end
        @count=Work.all(:type=>params[:type]).count
        set_pagination @count,params[:page]

        @feed=Work.all(:type=>params[:type]).page @page, :order=>@work_tri
        @work_tri=params[:tri] || "recent"
        return request.xhr? ? works_json(@feed) : haml(:'publication/index')
      else
        404
      end

    end #}}}

  end
end


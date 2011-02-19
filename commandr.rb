require 'bundler'


Bundler.require :default

DataMapper::Pagination.defaults[:size] = 5
DataMapper::Pagination.defaults[:per_page] = 5

require 'model'
require 'digest/sha1'
require 'salt' #Algorithm super secret indéchiffrable
require 'app/controllers/publications'
require 'app/controllers/users'
require 'app/controllers/types'


class App < Sinatra::Base

  include PublicationsController #Show,List,Edit,Delete,New(Codes,Iamges)
  include UsersController
  include TypesController

  use Rack::MethodOverride

  enable :sessions
  enable :static
  set :public, File.join(File.dirname(__FILE__), 'public')

  # Home
  get '/' do #{{{

    if session["username"]
      redirect '/feed'
    else
      redirect '/publication'
    end

  end #}}}

  get '/login' do #{{{
    @erreur=" "
    haml :'user/login'
  end #}}}

  post '/login' do #{{{

    @user=User.first(:username=>params[:username])
    @login=false
    @password=Digest::SHA1.hexdigest(params[:password])

    if salt(params[:username],@password)==@user.password
      session["username"]||=@user.username
      session["id"]||=@user.id
      @login=@user.username
    else
      @login=false
    end

    if @login
      if request.xhr? 
        return "true"
      else
        redirect "/user/#{@login}"
      end
    else
      if request.xhr?
        return "false"
      else
        @erreur="Les informations de connexion sont invalides"
        haml :'user/login'
      end
    end

  end #}}}

  get '/logout' do #{{{

    session["username"]=nil
    session["id"]=nil
    redirect "/login"

  end #}}}



  def works_json feed # {{{
    {:html => haml(:_liste, :layout => false, :locals => { :feed => feed }),
     :pagination => @total_page,
    }.to_json
  end # }}}

  def set_pagination count,page

    @page=page.to_i
    @page=1 if @page==0
    @total_page=(count.to_f/5).ceil

  end

  def set_self username
    @self=User.first(:fields=>[:id,:username],:username=>username)
  end



  ##### HELPERS #####
  helpers do 
    def set_tags
      cpt=0
      request.path.each_char do |i|
        cpt=cpt+1 if i=="/"
      end

      if cpt==2
        return '<script type="text/javascript" src="../js/global.js"></script>'
        #<link href="../css/global.css" rel="stylesheet" type="text/css"/>'
      else
        return '<script type="text/javascript" src="js/global.js"></script>'
        #<link href="../css/global.css" rel="stylesheet" type="text/css"/>'
      end
    end
   
    def distance_of_time_in_words(time)
      from_time=time.to_time
      to_time=Time.now
      distance_in_minutes = (((to_time - from_time).abs)/60).round
      distance_in_seconds = ((to_time - from_time).abs).round
      case distance_in_minutes
          when 0..1
              case distance_in_seconds
                  when 0..5   then 'less than 5 seconds ago'
                  when 6..10  then 'less than 10 seconds ago'
                  when 11..20 then 'less than 20 seconds ago'
                  when 21..40 then 'half a minute ago'
                  when 41..59 then 'less than a minute ago'
                  else             '1 minute ago'
              end

              when 2..45           then "#{distance_in_minutes} minutes ago"
              when 46..90          then 'about 1 hour ago'
              when 90..1440        then "about #{(distance_in_minutes / 60).round} hours ago"
              when 1441..2880      then '1 day ago'
              when 2881..525961    then Time.at(from_time).strftime("%e %b")
          else                      Time.at(from_time).strftime("%e %B %Y")
      end
    end
   
    def is_favorite user,work
      if Favorite.first(:fields=>[:work_id],:user=> user, :work=>work)
        return "favori"
      else
        return nil
      end
    end
    def is_self user,session
      if user==session
        return "self"
      else
        return nil
      end
    end
  end
end



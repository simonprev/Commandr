require 'bundler'


Bundler.require :default

DataMapper::Pagination.defaults[:size] = 7
DataMapper::Pagination.defaults[:per_page] = 7

require_rel 'app/'
require 'digest/sha1'


class Commandr < Sinatra::Base

  use Rack::MethodOverride
  use Rack::Flash



  enable :sessions
  enable :static
  set :public, File.join(File.dirname(__FILE__), 'public')


  before { set_self session["username"] }

  # Home
  get '/' do #{{{

    if session["username"]
      redirect '/feed'
    else
      redirect '/publications'
    end

  end #}}}



  include LoginController
  include PublicationsController
  include UsersController
  include TypesController



  def works_json feed # {{{
    {:html => haml(:_liste, :layout => false, :locals => { :feed => feed }),
     :pagination => @total_page,
    }.to_json
  end # }}}

  def users_json users # {{{
    {:html => haml(:'user/_liste_user', :layout => false, :locals => { :users => users }),
     :pagination => @total_page,
    }.to_json
  end # }}}

  ##### HELPERS #####
  helpers do 

  def set_pagination count,page

    @page=page.to_i
    @page=1 if @page==0
    @total_page=(count.to_f/7).ceil
    @total_page=1 if @total_page==0
    @count=count

  end

  def set_self username
    @self=User.first(:fields=>[:id,:username],:username=>username)
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

  def link_to(url,text=url,opts={})
    attributes = ""
    opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
    "<a href=\"#{url}\" #{attributes}>#{text}</a>"
  end
  
  def lien_actif? titre
    if request.path.index titre then
      return "actif"
    else
      return "normal"
    end
  end 
  end
end



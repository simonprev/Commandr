require 'bundler'
Bundler.require :default

require 'model.rb'


DataMapper::Pagination.defaults[:size] = 5
DataMapper::Pagination.defaults[:per_page] = 5

class App < Sinatra::Base
  use Rack::MethodOverride
  enable :sessions
  enable :static
  puts "****************************"
  set :public, File.join(File.dirname(__FILE__), 'public')

  # Home
  get '/' do #{{{

    if session["username"]
      redirect '/feed'
    else
      haml :index
    end

  end #}}}

  # Dernière activités
  get '/feed' do #{{{
    if session["username"]
      set_titre "Dernières Activités"
      set_self session["username"]

      @friends=[]
      @self.friends.each do |user|
        @friends << user.id
      end

      @friends << @self.id

      @count=Work.all(:user_id=>@friends).count
      set_pagination @count,params[:page]

      @feed=Work.all(:order=>:updated_at.desc, :user_id=>@friends).page @page

      haml :code

    else
      redirect '/'
    end
  end #}}}

  # Liste de codes
  get '/code' do #{{{
    set_titre "Code"
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

    haml :code

  end #}}}

  # Nouveau Code
  get '/new' do #{{{

    if session["username"]
      haml :new
    else
      redirect '/login'
    end

  end #}}}

    get '/new_code' do #{{{

    if session["username"]
      haml :new_code
    else
      redirect '/login'
    end

  end #}}}

  #save new
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
      haml :new
    end

  end #}}}

  # Nouveau Code
  get '/new_image' do #{{{

    if session["username"]
      haml :new_image
    else
      redirect '/login'
    end

  end #}}}

  post '/new_image' do
    @work = Work.new(:titre => params[:work_title],
                     :body => "Aucun code pour une image",
                     :desc => params[:work_desc],
                     :type  => "image",
                     :created_at => Time.now.to_i,
                     :user_id=>session["id"]
                     )

    if @work.save && params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
      File.open(File.join(Dir.pwd,"public/files", @work.id.to_s), "wb") { |f| f.write(tmpfile.read) }
      redirect "/#{@work.id}"
    else
      unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
        @work.errors.add :fichier,"Vous devez choisir un fichier"
      end
      haml :new_image
    end

  end

  ## Auteur related routes ##

  # List Auteurs
  get '/user' do #{{{

    @count=User.all(:order=>:updated_at.desc).count
    set_pagination @count,params[:page]

    @users=User.all().page @page, :order=>:updated_at.desc
    haml :all_user

  end #}}}

  # Profil User
  get '/user/:user' do #{{{
    set_titre "Code"
    set_self session["username"]
    @user=User.first(:username=>params[:user])
    @is_friend=Friendship.between @self,@user

    @follow=[]
    @user.friends.each do |i|
      @follow << i
    end

    @all_followers=Friendship.all(:target=>@user)
    @followers=[]
    @all_followers.each do |i|
      @followers << i.source
    end

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



    haml :user

  end #}}}

  # Suivre ou retirer User
  post '/user/:user' do #{{{
    set_self session["username"]
    @user=User.first(:username=>params[:user])

    if !@self.friends.include? @user
      @friends=Friendship.new(:source => @self, :target=> @user)
      @friends.save
    else
      @friends=Friendship.first(:source => @self, :target=> @user)
      @friends.destroy
    end

    redirect "/user/#{params[:user]}"

  end #}}}


  # List Langages
  get '/type' do

    haml :all_type

  end

  # Code par Langage
  get '/type/:type' do

    set_self session["username"]
    set_titre "Code - #{params[:type].capitalize}"

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

    haml :code

  end

  # Page Login
  get '/login' do #{{{
    @erreur=" "
    haml :login
  end #}}}

  # Verification Login /AJAX/
  post '/login' do #{{{

    @users=User.all
    @login=false
    @users.each do |user|
      if params[:username]==user.username
        if params[:password]==user.password
          session["username"]||=user.username
          session["id"]||=user.id
          @login=user.username
        else
          @login=false
        end
      end
    end

    if @login
      if request.xhr? #AAAAJJJJAAAAXXXXX
        return "true"
      else
        redirect "/user/#{@login}"
      end
    else
      if request.xhr?
        return "false"
      else
        @erreur="Les informations de connexion sont invalides"
        haml :login
      end
    end

  end #}}}

  # Logout User
  get '/logout' do #{{{

    session["username"]=nil
    session["id"]=nil
    redirect "/login"

  end #}}}

## ID related routes ##
  get %r{^\/([0-9]{0,4})$} do |id|

    set_self session["username"]
    @code=Work.get(id)
    if @code
      @user=@code.user
      @comments=Comment.all(:work_id=>id)
      @is_favorite=Favorite.is_favorite @self,@code

      if !session["views"]
        session["views"]=[]
      end

      if !session["views"].include? id.to_i
        session["views"] << id.to_i
        @code.update!(:views=>@code.views+1)
      end

      haml :show
    else
      redirect "/sorry_not_found"
    end

  end #}}}

  # Mettre ou enlever des favoris
  get '/:id/fav' do #{{{
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

    if !request.xhr?
      redirect "/#{params[:id]}"
    else
      if @is_favorite
        return "false"
      else
        return "true"
      end
    end

  end #}}}

  # Posté un commentaire
  post '/:id' do #{{{

    @comment=Comment.create(:nom  => session["username"],
                            :body => params[:comment_body],
                            :work_id=>params[:id],
                            :user_id=> session["id"])

    redirect "/#{params[:id]}"


  end #}}}



  delete '/:id/destroy_it' do #{{{

    puts "destroy #{params[:id]}"
    @code=Work.get(params[:id])

    if @code.destroy
      redirect "/"
    else
      redirect"/#{params[:id]}"
    end

  end #}}}

  # Page modification d'un code
  get '/:id/modify' do #{{{

    @code=Work.get(params[:id])
    if session["id"]==@code.user_id
      haml :modify
    else
      redirect "/#{params[:id]}"
    end

  end #}}}

  # Enregistrer les modifications
  put "/:id/modify" do #{{{
    @error=[]
    @code=Work.get(params[:id])
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



  error 404 do
    '404'
  end


  def is_self person1,person2
    if person1==person2
      return "by_user"
    else
      return nil
    end
  end

  def set_pagination count,page

    @page=page.to_i
    @page=1 if @page==0
    @total_page=(count.to_f/5).ceil

  end

  def set_titre titre
    @titre=titre
  end

  def set_self username
    @self=User.first(:fields=>[:id,:username],:username=>username)
  end

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

  def distance_of_time_in_words(from_time)
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

end


